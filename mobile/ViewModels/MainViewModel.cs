using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using FaceScaner.Models;
using FaceScaner.Services;

namespace FaceScaner.ViewModels;

public partial class MainViewModel : ObservableObject
{
    private readonly FaceRecognitionService _service;

    public MainViewModel(FaceRecognitionService service)
    {
        _service = service;
    }

    [ObservableProperty] private bool isScanning;
    [ObservableProperty] private bool hasResult;
    [ObservableProperty] private bool hasError;
    [ObservableProperty] private string errorMessage = "";
    [ObservableProperty] private RecognitionResult? currentResult;
    [ObservableProperty] private ImageSource? previewImage;
    [ObservableProperty] private string newPersonName = "";
    [ObservableProperty] private bool showAddPanel;
    [ObservableProperty] private bool isAdding;

    private List<ScanHistoryItem> _history = [];
    private FileResult? _lastFile;
    public List<ScanHistoryItem> History => _history;
    public bool HasHistory => _history.Count > 0;

    [RelayCommand]
    private async Task ScanWithCameraAsync()
    {
        try
        {
            if (!MediaPicker.Default.IsCaptureSupported)
            { ShowError("Aparat niedostepny."); return; }
            var photo = await MediaPicker.Default.CapturePhotoAsync();
            if (photo is null) return;
            await ProcessMediaFileAsync(photo);
        }
        catch (PermissionException) { ShowError("Brak uprawnien do aparatu."); }
        catch (Exception ex) { ShowError(ex.Message); }
    }

    [RelayCommand]
    private async Task PickFromGalleryAsync()
    {
        try
        {
            var photo = await MediaPicker.Default.PickPhotoAsync();
            if (photo is null) return;
            await ProcessMediaFileAsync(photo);
        }
        catch (PermissionException) { ShowError("Brak uprawnien do galerii."); }
        catch (Exception ex) { ShowError(ex.Message); }
    }

    [RelayCommand]
    private void Clear()
    {
        CurrentResult = null; PreviewImage = null;
        HasResult = false; HasError = false; ErrorMessage = "";
    }

    [RelayCommand]
    private async Task AddToDatabase()
    {
        if (string.IsNullOrWhiteSpace(NewPersonName))
        {
            ShowError("Podaj imię i nazwisko.");
            return;
        }
        if (_lastFile is null)
        {
            ShowError("Brak zdjęcia.");
            return;
        }

        IsAdding = true;
        try
        {
            await using var stream = await _lastFile.OpenReadAsync();
            var success = await _service.AddPersonAsync(stream, _lastFile.FileName, NewPersonName.Trim());
            if (success)
            {
                ShowAddPanel = false;
                NewPersonName = "";
                await Shell.Current.DisplayAlert("Sukces", "Dodano do bazy danych.", "OK");
            }
            else
            {
                ShowError("Nie udało się dodać osoby.");
            }
        }
        finally { IsAdding = false; }
    }

    private async Task ProcessMediaFileAsync(FileResult file)
    {
        IsScanning = true; HasResult = false; HasError = false;
        PreviewImage = ImageSource.FromFile(file.FullPath);
        try
        {
            await using var stream = await file.OpenReadAsync();
            var result = await _service.RecognizeFaceAsync(stream, file.FileName);
            _lastFile = file;
            ShowAddPanel = true;
            result.ImagePath = file.FullPath;
            CurrentResult = result;
            
            if (!result.Success)
            {
                ShowError(result.ErrorMessage ?? "Nieznany błąd");
                return;
            }

            HasResult = true;
            
            if (!result.Matched)
            {
                ShowError(result.Message ?? "Nie rozpoznano twarzy");
            }
            
            _history.Insert(0, new ScanHistoryItem { Result = result });
            if (_history.Count > 50) _history = _history.Take(50).ToList();
            OnPropertyChanged(nameof(History));
            OnPropertyChanged(nameof(HasHistory));
        }
        catch (Exception ex) { ShowError(ex.Message); }
        finally { IsScanning = false; }
    }

    private void ShowError(string message)
    { HasError = true; HasResult = false; ErrorMessage = message; IsScanning = false; }
}