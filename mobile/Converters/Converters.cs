using System.Globalization;

namespace FaceScaner.Converters;

public class NullToBoolConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        bool isNull = value is null;
        bool invert = parameter?.ToString() == "invert";
        return invert ? isNull : !isNull;
    }
    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
        => throw new NotImplementedException();
}

public class ConfidenceToWidthConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is not double confidence) return 0d;
        double maxWidth = parameter is string s && double.TryParse(s, System.Globalization.NumberStyles.Any, CultureInfo.InvariantCulture, out var w) ? w : 280d;
        return Math.Clamp(confidence, 0, 1) * maxWidth;
    }
    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
        => throw new NotImplementedException();
}