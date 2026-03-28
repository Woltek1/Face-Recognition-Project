using FaceScaner.Models;
using System.Text.Json;
using Microsoft.Extensions.Configuration;

namespace FaceScaner.Services;

public class FaceRecognitionService
{
    private readonly HttpClient _httpClient;
    private readonly string _apiBaseUrl;

    public FaceRecognitionService(IConfiguration configuration)
    {
        _httpClient = new HttpClient
        {
            Timeout = TimeSpan.FromSeconds(30)
        };

        // Read API URL from configuration or use default
        _apiBaseUrl = configuration["ApiBaseUrl"] ?? "http://10.0.2.2:8000/api";
    }

    public async Task<RecognitionResult> RecognizeFaceAsync(Stream imageStream, string fileName)
    {
        try
        {
            // Prepare multipart form data
            using var content = new MultipartFormDataContent();
            var streamContent = new StreamContent(imageStream);
            streamContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("image/jpeg");
            content.Add(streamContent, "image", fileName);

            // Send request to API
            var response = await _httpClient.PostAsync($"{_apiBaseUrl}/recognize", content);
            var responseString = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                // Try to parse error message
                try
                {
                    var errorObj = JsonSerializer.Deserialize<JsonElement>(responseString);
                    var errorMsg = errorObj.GetProperty("error").GetString();
                    return new RecognitionResult
                    {
                        Success = false,
                        ErrorMessage = errorMsg ?? "Nieznany błąd serwera"
                    };
                }
                catch
                {
                    return new RecognitionResult
                    {
                        Success = false,
                        ErrorMessage = $"Błąd HTTP {response.StatusCode}"
                    };
                }
            }

            // Parse successful response
            var apiResponse = JsonSerializer.Deserialize<ApiRecognizeResponse>(responseString,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

            if (apiResponse == null)
            {
                return new RecognitionResult
                {
                    Success = false,
                    ErrorMessage = "Nieprawidłowa odpowiedź z serwera"
                };
            }

            if (!apiResponse.Matched)
            {
                return new RecognitionResult
                {
                    Success = true,
                    Matched = false,
                    Message = apiResponse.Message ?? "Nie rozpoznano twarzy"
                };
            }

            return new RecognitionResult
            {
                Success = true,
                Matched = true,
                PersonName = apiResponse.Person ?? "Nieznany",
                PersonId = 0,
                Confidence = apiResponse.Confidence,
                ScannedAt = DateTime.Now
            };
        }
        catch (HttpRequestException ex)
        {
            return new RecognitionResult
            {
                Success = false,
                ErrorMessage = $"Błąd połączenia: {ex.Message}"
            };
        }
        catch (TaskCanceledException)
        {
            return new RecognitionResult
            {
                Success = false,
                ErrorMessage = "Przekroczono czas oczekiwania (30s)"
            };
        }
        catch (Exception ex)
        {
            return new RecognitionResult
            {
                Success = false,
                ErrorMessage = $"Nieoczekiwany błąd: {ex.Message}"
            };
        }
    }

    // Helper classes for JSON deserialization
    private class ApiRecognizeResponse
    {
        public bool Matched { get; set; }
        public string? Person { get; set; }
        public double Confidence { get; set; }
        public string? Message { get; set; }
    }

    public async Task<bool> AddPersonAsync(Stream imageStream, string fileName, string name)
    {
        try
        {
            using var content = new MultipartFormDataContent();
            var streamContent = new StreamContent(imageStream);
            streamContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("image/jpeg");
            content.Add(streamContent, "image", fileName);
            content.Add(new StringContent(name), "name");

            var response = await _httpClient.PostAsync($"{_apiBaseUrl}/persons", content);
            return response.IsSuccessStatusCode;
        }
        catch { return false; }
    }

}