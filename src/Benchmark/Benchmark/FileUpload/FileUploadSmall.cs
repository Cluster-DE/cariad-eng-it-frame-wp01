using System.Threading.Tasks;
using BenchmarkDotNet.Attributes;

namespace Benchmark.FileUpload;

public class FileUploadSmall : FileUploadBase
{
    protected override string LocalFilePath => "files/file-example_PDF_1MB.pdf";

    [Benchmark(Description = "Single-threaded upload of a 1.0MB file", Baseline = true)]
    public async Task BenchmarkUploadFileAsync()
    {
        await UploadFileAsync();
    }
    
    [Benchmark(Description = "Multi-threaded upload (10 in parallel) of a 1.0MB file")]
    public async Task BenchmarkUploadFileParallelAsync()
    {
        await UploadFileParallelAsync();
    }
}