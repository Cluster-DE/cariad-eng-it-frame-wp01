using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using Azure;
using Azure.Storage.Files.Shares;
using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Engines;
using BenchmarkDotNet.Jobs;

namespace Benchmark.FileUpload;

[SimpleJob(RunStrategy.ColdStart, RuntimeMoniker.Net80, warmupCount: 1, iterationCount: Constants.Measurement.IterationCount)]
[Config(typeof(BenchmarkConfig))]
[ArtifactsPath("BenchmarkDotNet.Artifacts")]
public class FileUploadBase
{
    protected virtual string LocalFilePath => "";
    
    private ShareClient _shareClient;
    private ShareDirectoryClient _shareDirectoryClient;
    
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
    }

    protected async Task UploadFileAsync()
    {
        const int maxChunkSize = 4 * 1024 * 1024; // 4MB
        var fileClient = _shareDirectoryClient.GetFileClient($"{Guid.NewGuid()}.pdf");
    
        await using var stream = File.OpenRead(LocalFilePath);
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
    }
    
    protected async Task UploadFileParallelAsync()
    {
        var tasks = new List<Task>();

        for (var i = 0; i < Constants.Measurement.DegreeOfParallelism; i++)
        {
            tasks.Add(Task.Run(async () =>
            {
                await UploadFileAsync();
            }));
        }

        await Task.WhenAll(tasks);
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