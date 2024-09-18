using BenchmarkDotNet.Columns;
using BenchmarkDotNet.Configs;
using BenchmarkDotNet.Exporters;
using BenchmarkDotNet.Loggers;
using BenchmarkDotNet.Order;

namespace Benchmark;

public class BenchmarkConfig : ManualConfig
{
    public BenchmarkConfig()
    {
        CreateEmpty();
        
        AddColumn(
            TargetMethodColumn.Method,
            StatisticColumn.Median,
            StatisticColumn.Mean,
            StatisticColumn.Min,
            StatisticColumn.Max,
            StatisticColumn.Iterations,
            StatisticColumn.OperationsPerSecond);
        
        AddExporter(new HtmlExporter());
        AddExporter(MarkdownExporter.GitHub);
        AddLogger(ConsoleLogger.Default);
        
        WithOption(ConfigOptions.JoinSummary, true);
        WithOption(ConfigOptions.DisableLogFile, true);
    }
}