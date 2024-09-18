using System.Threading.Tasks;
using BenchmarkDotNet.Attributes;

namespace Benchmark;

public class FileUploadMedium : FileUploadBase
{
    private const string LocalFilePath = "files/file-example_PDF_2MB.pdf";

    [Benchmark(Description = "Single-threaded upload with 2.0MB file")]
    public async Task BenchmarkUploadFileAsync()
    {
        await UploadFileAsync(LocalFilePath, Constants.Strings.NamePrefixUploadMedium);
    }
    
    [Benchmark(Description = "Multi-threaded upload (10 in parallel) with 2.0MB file")]
    public async Task BenchmarkUploadFileParallelAsync()
    {
        await UploadFileParallelAsync(LocalFilePath, Constants.Strings.NamePrefixUploadMedium);
    }
}