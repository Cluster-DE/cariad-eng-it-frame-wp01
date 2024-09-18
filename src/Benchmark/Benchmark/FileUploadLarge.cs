using System.Threading.Tasks;
using BenchmarkDotNet.Attributes;

namespace Benchmark;

public class FileUploadLarge : FileUploadBase
{
    private const string LocalFilePath = "files/file-example_PDF_4MB.pdf";

    [Benchmark(Description = "Single-threaded upload with 4.0MB file")]
    public async Task BenchmarkUploadFileAsync()
    {
        await UploadFileAsync(LocalFilePath, Constants.Strings.NamePrefixUploadLarge);
    }
    
    [Benchmark(Description = "Multi-threaded upload (10 in parallel) with 4.0MB file")]
    public async Task BenchmarkUploadFileParallelAsync()
    {
        await UploadFileParallelAsync(LocalFilePath, Constants.Strings.NamePrefixUploadLarge);
    }
}