using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using Azure;
using Azure.Storage.Files.Shares;
using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Engines;
using BenchmarkDotNet.Jobs;

namespace Benchmark;

[SimpleJob(RunStrategy.ColdStart, RuntimeMoniker.Net80, warmupCount: 1, iterationCount: Constants.Measurement.IterationCount)]
[Config(typeof(BenchmarkConfig))]
[ArtifactsPath("BenchmarkDotNet.Artifacts")]
public class FileUploadBase
{
    private ShareClient _shareClient;
    private ShareDirectoryClient _shareDirectoryClient;
    
    [GlobalSetup]
    public async Task SetupAsync()
    {
        var connectionString = Environment.GetEnvironmentVariable(Constants.AzureFileShare.ConnectionStringName);
        
        _shareClient = new ShareClient(connectionString, Constants.AzureFileShare.ShareName);
        await _shareClient.CreateIfNotExistsAsync();
        
        var dirNameWithDateTime = $"{DateTime.Now:yyyyMMdd_HHmmss}";
        
        _shareDirectoryClient = _shareClient.GetDirectoryClient(dirNameWithDateTime);
        await _shareDirectoryClient.CreateIfNotExistsAsync();
    }

    protected async Task UploadFileAsync(string filePath, string fileNamePrefix)
    {
        const int maxChunkSize = 4 * 1024 * 1024; // 4MB
        var fileClient = _shareDirectoryClient.GetFileClient($"{fileNamePrefix}-{Guid.NewGuid()}.pdf");
    
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
    }
    
    protected async Task UploadFileParallelAsync(string filePath, string fileNamePrefix)
    {
        var tasks = new List<Task>();

        for (var i = 0; i < Constants.Measurement.DegreeOfParallelism; i++)
        {
            tasks.Add(Task.Run(async () =>
            {
                await UploadFileAsync(filePath, fileNamePrefix);
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