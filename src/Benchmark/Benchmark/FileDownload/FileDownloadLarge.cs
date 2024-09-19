using System.Threading.Tasks;
using BenchmarkDotNet.Attributes;

namespace Benchmark.FileDownload;

public class FileDownloadLarge : FileDownloadBase
{
    protected override string LocalFilePath => "files/file-example_PDF_4MB.pdf";

    [Benchmark(Description = "Single-threaded download of a 4.0MB file", Baseline = true)]
    public async Task BenchmarkDownloadFileAsync()
    {
        await DownloadFileAsync();
    }
    
    [Benchmark(Description = "Multi-threaded download (10 in parallel) of a 4.0MB file")]
    public async Task BenchmarkDownloadFileParallelAsync()
    {
        await DownloadFileParallelAsync();
    }
}