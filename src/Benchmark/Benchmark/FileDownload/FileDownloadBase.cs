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

/// <summary>
/// Base class for handling file downloads in benchmarking scenarios.
/// </summary>
/// <remarks>
/// Provides setup, cleanup, and asynchronous file download methods.
/// Utilizes BenchmarkDotNet for measuring performance.
/// </remarks>
[SimpleJob(
    RunStrategy.ColdStart,
    RuntimeMoniker.Net80,
    warmupCount: 1,
    iterationCount: Constants.Measurement.IterationCount)]
[Config(typeof(BenchmarkConfig))]
[ArtifactsPath("BenchmarkDotNet.Artifacts")]
public class FileDownloadBase
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
    /// The name of the file that is currently being worked on.
    /// This variable is assigned during the setup process when a file is uploaded.
    /// </summary>
    private string _workingFileName = string.Empty;

    /// <summary>
    /// Asynchronously sets up the environment necessary for file download benchmarks.
    /// This includes establishing connections to Azure File Share, creating
    /// directory clients, and uploading a sample file.
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

        _workingFileName = await UploadFileAsync(LocalFilePath);
        
        Console.WriteLine("Upload of SampleFile completed");
    }

    /// <summary>
    /// Asynchronously uploads a file to an Azure File Share. The file is uploaded in chunks of
    /// 4MB to handle large files efficiently (Put Range Limit). The file is specified by the LocalFilePath property.
    /// </summary>
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

    /// <summary>
    /// Downloads a file asynchronously from the Azure Share Directory and streams its content.
    /// </summary>
    protected async Task DownloadFileAsync()
    {
        var fileClient = _shareDirectoryClient.GetFileClient(_workingFileName);

        var fileDownloadResult = await fileClient.DownloadAsync();

        if (fileDownloadResult.HasValue)
        {
            await ReadStreamToEnd(fileDownloadResult.Value.Content);
        }
    }

    /// <summary>
    /// Downloads a file in parallel using multiple asynchronous tasks.
    /// </summary>
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

    /// <summary>
    /// Reads the entire content of a given stream asynchronously to the end.
    /// </summary>
    /// <param name="input">The input stream to read from.</param>
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

    /// <summary>
    /// Cleans up resources used during the file download benchmark.
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