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

/// <summary>
/// Base class for handling file uploads in benchmarking scenarios.
/// </summary>
/// <remarks>
/// Provides setup, cleanup, and asynchronous file upload methods.
/// Utilizes BenchmarkDotNet for measuring performance.
/// </remarks>
[SimpleJob(
    RunStrategy.ColdStart,
    RuntimeMoniker.Net80,
    warmupCount: 1,
    iterationCount: Constants.Measurement.IterationCount)]
[Config(typeof(BenchmarkConfig))]
[ArtifactsPath("BenchmarkDotNet.Artifacts")]
public class FileUploadBase
{
    /// <summary>
    /// Gets the file path of the local file to be uploaded.
    /// The file path is specific to the subclass implementation and defines
    /// the location of a file used in the benchmarking tests.
    /// </summary>
    protected virtual string LocalFilePath => "";
    
    private ShareClient _shareClient;
    
    private ShareDirectoryClient _shareDirectoryClient;

    /// <summary>
    /// Sets up the asynchronous environment for file upload operations.
    /// Initializes the ShareClient and ShareDirectoryClient by creating
    /// the necessary Azure File Share resources if they do not already exist.
    /// </summary>
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

    /// <summary>
    /// Asynchronously uploads a file to an Azure File Share. The file is uploaded in chunks of
    /// 4MB to handle large files efficiently (Put Range Limit). The file is specified by the LocalFilePath property.
    /// </summary>
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

    /// <summary>
    /// Uploads a file to a share storage in parallel using multiple threads.
    /// Kicks off multiple tasks to perform the upload concurrently.
    /// </summary>
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

    /// <summary>
    /// Cleans up resources used during the file upload benchmark.
    /// </summary>
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