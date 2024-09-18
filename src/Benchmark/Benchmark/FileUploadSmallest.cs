using System.Threading.Tasks;
using BenchmarkDotNet.Attributes;

namespace Benchmark;

public class FileUploadSmallest : FileUploadBase
{
    private const string LocalFilePath = "files/file-example_PDF_0.5MB.pdf";

    [Benchmark(Description = "Single-threaded upload with 0.5MB file")]
    public async Task BenchmarkUploadFileAsync()
    {
        await UploadFileAsync(LocalFilePath, Constants.Strings.NamePrefixUploadSmallest);
    }
    
    [Benchmark(Description = "Multi-threaded upload (10 in parallel) with 0.5MB file")]
    public async Task BenchmarkUploadFileParallelAsync()
    {
        await UploadFileParallelAsync(LocalFilePath, Constants.Strings.NamePrefixUploadSmallest);
    }
}