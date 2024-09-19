namespace Benchmark;

public static class Constants
{
    public static class AzureFileShare
    {
        public const string ConnectionStringEnvVarName = "STORAGE_ACCOUNT_CONNECTION_STRING";
    
        public const string ShareName = "benchmark";
    }

    public static class Measurement
    {
        public const int DegreeOfParallelism = 10;

        public const int IterationCount = 10;
    }
}