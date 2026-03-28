namespace FaceScaner.Models;

public class RecognitionResult
{
    public bool Success { get; set; }
    public bool Matched { get; set; }
    public string? PersonName { get; set; }
    public int? PersonId { get; set; }
    public double Confidence { get; set; }
    public string? Message { get; set; }
    public string? ErrorMessage { get; set; }
    public DateTime ScannedAt { get; set; } = DateTime.Now;
    public string? ImagePath { get; set; }

    public string ConfidencePercent => $"{Confidence * 100:F1}%";
    public string ConfidenceLabel => Confidence switch
    {
        >= 0.90 => "Pewny",
        >= 0.75 => "Prawdopodobny",
        >= 0.60 => "Niepewny",
        _ => "Niska pewnosc"
    };
    public string ConfidenceColor => Confidence switch
    {
        >= 0.90 => "#22C55E",
        >= 0.75 => "#F59E0B",
        >= 0.60 => "#F97316",
        _ => "#EF4444"
    };
}

public class ScanHistoryItem
{
    public RecognitionResult Result { get; set; } = new();
    public string TimeAgo => GetTimeAgo(Result.ScannedAt);
    private static string GetTimeAgo(DateTime dt)
    {
        var diff = DateTime.Now - dt;
        if (diff.TotalSeconds < 60) return "przed chwila";
        if (diff.TotalMinutes < 60) return $"{(int)diff.TotalMinutes} min temu";
        if (diff.TotalHours < 24) return $"{(int)diff.TotalHours} godz. temu";
        return dt.ToString("dd.MM.yyyy");
    }
}