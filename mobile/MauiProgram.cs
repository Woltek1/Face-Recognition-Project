using FaceScaner.Services;
using FaceScaner.ViewModels;
using FaceScaner.Views;
using Microsoft.Extensions.Configuration;
using System.Reflection;

namespace FaceScaner;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        var builder = MauiApp.CreateBuilder();
        builder.UseMauiApp<App>();

        // Wczytaj appsettings.json
        var assembly = Assembly.GetExecutingAssembly();
        using var stream = assembly.GetManifestResourceStream("FaceScaner.appsettings.json");
        if (stream != null)
        {
            var config = new ConfigurationBuilder().AddJsonStream(stream).Build();
            builder.Configuration.AddConfiguration(config);
        }

        builder.Services.AddSingleton<FaceRecognitionService>();
        builder.Services.AddTransient<MainViewModel>();
        builder.Services.AddTransient<MainPage>();

        return builder.Build();
    }
}