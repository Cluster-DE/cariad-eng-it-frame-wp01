using System.Threading.Tasks;
using BenchmarkDotNet.Attributes;

namespace Benchmark.FileUpload;

public class FileUploadSmallest : FileUploadBase
{
    protected override string LocalFilePath => "files/file-example_PDF_0.5MB.pdf";

    [Benchmark(Description = "Single-threaded upload of a 0.5MB file", Baseline = true)]
    public async Task BenchmarkUploadFileAsync()
    {
        await UploadFileAsync();
    }
    
    [Benchmark(Description = "Multi-threaded upload (10 in parallel) of a 0.5MB file")]
    public async Task BenchmarkUploadFileParallelAsync()
    {
        await UploadFileParallelAsync();
    }
}