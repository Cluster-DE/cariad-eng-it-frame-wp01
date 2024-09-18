using System.Threading.Tasks;
using BenchmarkDotNet.Attributes;

namespace Benchmark;

public class FileUploadSmall : FileUploadBase
{
    private const string LocalFilePath = "files/file-example_PDF_1MB.pdf";

    [Benchmark(Description = "Single-threaded upload with 1.0MB file")]
    public async Task BenchmarkUploadFileAsync()
    {
        await UploadFileAsync(LocalFilePath, Constants.Strings.NamePrefixUploadSmall);
    }
    
    [Benchmark(Description = "Multi-threaded upload (10 in parallel) with 1.0MB file")]
    public async Task BenchmarkUploadFileParallelAsync()
    {
        await UploadFileParallelAsync(LocalFilePath, Constants.Strings.NamePrefixUploadSmall);
    }
}