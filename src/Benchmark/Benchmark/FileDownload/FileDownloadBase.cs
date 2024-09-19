using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using Azure;
using Azure.Storage.Files.Shares;
using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Engines;
using BenchmarkDotNet.Jobs;

namespace Benchmark.FileDownload;

[SimpleJob(RunStrategy.ColdStart, RuntimeMoniker.Net80, warmupCount: 1, iterationCount: Constants.Measurement.IterationCount)]
[Config(typeof(BenchmarkConfig))]
[ArtifactsPath("BenchmarkDotNet.Artifacts")]
public class FileDownloadBase
{
    protected virtual string LocalFilePath => "";
    
    private ShareClient _shareClient;
    private ShareDirectoryClient _shareDirectoryClient;
    
    private string _workingFileName = string.Empty;
    
    [GlobalSetup]
    public async Task SetupAsync()
    {
        var connectionString = Environment.GetEnvironmentVariable(Constants.AzureFileShare.ConnectionStringEnvVarName);
        
        _shareClient = new ShareClient(connectionString, Constants.AzureFileShare.ShareName);
        await _shareClient.CreateIfNotExistsAsync();
        
        Console.WriteLine("Setup of ShareClient completed");
        
        var dirNameWithDateTime = $"{DateTime.Now:yyyyMMdd_HHmmss}-{Guid.NewGuid()}";
        
        _shareDirectoryClient = _shareClient.GetDirectoryClient(dirNameWithDateTime);
        await _shareDirectoryClient.CreateIfNotExistsAsync();
        
        Console.WriteLine("Setup of ShareDirectoryClient completed");

        _workingFileName = await UploadFileAsync(LocalFilePath);
        
        Console.WriteLine("Upload of SampleFile completed");
    }

    private async Task<string> UploadFileAsync(string filePath)
    {
        const int maxChunkSize = 4 * 1024 * 1024; // 4MB
        var fileClient = _shareDirectoryClient.GetFileClient($"{Guid.NewGuid()}.pdf");
    
        await using var stream = File.OpenRead(filePath);
        await fileClient.CreateAsync(stream.Length);

        var fileOffset = 0L;
        var buffer = new byte[maxChunkSize];
        int bytesRead;

        while ((bytesRead = await stream.ReadAsync(buffer.AsMemory(0, maxChunkSize))) > 0)
        {
            using var chunkStream = new MemoryStream(buffer, 0, bytesRead);
            await fileClient.UploadRangeAsync(
                new HttpRange(fileOffset, bytesRead),
                chunkStream);
            fileOffset += bytesRead;
        }

        return fileClient.Name;
    }
    
    protected async Task DownloadFileAsync()
    {
        var fileClient = _shareDirectoryClient.GetFileClient(_workingFileName);

        var fileDownloadResult = await fileClient.DownloadAsync();

        if (fileDownloadResult.HasValue)
        {
            await ReadStreamToEnd(fileDownloadResult.Value.Content);
        }
    }
    
    protected async Task DownloadFileParallelAsync()
    {
        var tasks = new List<Task>();

        for (var i = 0; i < Constants.Measurement.DegreeOfParallelism; i++)
        {
            tasks.Add(Task.Run(async () =>
            {
                await DownloadFileAsync();
            }));
        }

        await Task.WhenAll(tasks);
    }
    
    private async Task ReadStreamToEnd(Stream input)
    {
        var buffer = new byte[10 * 1024 * 1024];
        using var ms = new MemoryStream();
        int read;
        while ((read = await input.ReadAsync(buffer)) > 0)
        {
            ms.Write(buffer, 0, read);
        }

        _ = ms.ToArray();
    }
    
    [GlobalCleanup]
    public async Task CleanupAsync()
    {
        var files = _shareDirectoryClient.GetFilesAndDirectories();
        
        foreach (var item in files)
        {
            if (item.IsDirectory) continue;
            
            var file = _shareDirectoryClient.GetFileClient(item.Name);

            await file.DeleteIfExistsAsync();
        }

        await _shareDirectoryClient.DeleteIfExistsAsync();
    }
}