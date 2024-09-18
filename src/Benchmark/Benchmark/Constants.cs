namespace Benchmark;

public static class Constants
{
    public static class AzureFileShare
    {
        public const string ConnectionStringName = "STORAGE_ACCOUNT_CONNECTION_STRING";
    
        public const string ShareName = "benchmark";
    }

    public static class Measurement
    {
        public const int DegreeOfParallelism = 10;

        public const int IterationCount = 50;
    }

    public static class Strings
    {
        public const string NamePrefixUploadSmallest = "upload_smallest";
        
        public const string NamePrefixUploadSmall = "upload_small";
        
        public const string NamePrefixUploadMedium = "upload_medium";
        
        public const string NamePrefixUploadLarge = "upload_large";
    }
}