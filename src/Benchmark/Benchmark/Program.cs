using BenchmarkDotNet.Running;

namespace Benchmark;

class Program
{
    public static void Main(string[] args)
    {
        BenchmarkSwitcher.FromAssembly(typeof(Program).Assembly).Run(args);
    } 
}