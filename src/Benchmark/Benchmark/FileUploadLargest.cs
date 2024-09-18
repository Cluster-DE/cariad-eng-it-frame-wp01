using System.Threading.Tasks;
using BenchmarkDotNet.Attributes;

namespace Benchmark;

public class FileUploadLargest : FileUploadBase
{
    private const string LocalFilePath = "files/file-example_PDF_10MB.pdf";

    [Benchmark(Description = "Single-threaded upload with 10.0MB file")]
    public async Task BenchmarkUploadFileAsync()
    {
        await UploadFileAsync(LocalFilePath, Constants.Strings.NamePrefixUploadLarge);
    }
    
    [Benchmark(Description = "Multi-threaded upload (10 in parallel) with 10.0MB file")]
    public async Task BenchmarkUploadFileParallelAsync()
    {
        await UploadFileParallelAsync(LocalFilePath, Constants.Strings.NamePrefixUploadLarge);
    }
}