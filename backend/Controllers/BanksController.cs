using CheckFillingAPI.Models;
using CheckFillingAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json;
using System.Security.Claims;

namespace CheckFillingAPI.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class BanksController : ControllerBase
{
    private readonly IBankService _bankService;
    private readonly IAuditService _auditService;

    public BanksController(IBankService bankService, IAuditService auditService)
    {
        _bankService = bankService;
        _auditService = auditService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var banks = await _bankService.GetAllBanksAsync();
        return Ok(new { banks });
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var bank = await _bankService.GetBankByIdAsync(id);
        if (bank == null)
        {
            return NotFound(new { message = "Banque non trouvée" });
        }
        return Ok(bank);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromForm] BankCreateRequest request)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

        var bank = new Bank
        {
            Code = request.Code,
            Name = request.Name,
            PositionsJson = "{}"
        };

        var createdBank = await _bankService.CreateBankAsync(bank, request.Pdf);

        // Log the action
        await _auditService.LogAction(userId, "CREATE_BANK", "Bank", createdBank.Id, new
        {
            code = createdBank.Code,
            name = createdBank.Name,
            pdfUrl = createdBank.PdfUrl
        });

        return CreatedAtAction(nameof(GetById), new { id = createdBank.Id }, createdBank);
    }

    [HttpPatch("{id}")]
    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromForm] BankUpdateRequest request)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        
        // Get old bank for audit log
        var oldBank = await _bankService.GetBankByIdAsync(id);
        if (oldBank == null)
        {
            return NotFound(new { message = "Banque non trouvée" });
        }

        var bank = new Bank
        {
            Code = request.Code ?? "",
            Name = request.Name ?? "",
            PositionsJson = request.Positions ?? "{}"
        };

        var updatedBank = await _bankService.UpdateBankAsync(id, bank, request.Pdf);
        if (updatedBank == null)
        {
            return NotFound(new { message = "Banque non trouvée" });
        }

        // Log the action
        await _auditService.LogAction(userId, "UPDATE_BANK", "Bank", id, new
        {
            oldValues = new { code = oldBank.Code, name = oldBank.Name },
            newValues = new { code = updatedBank.Code, name = updatedBank.Name }
        });

        return Ok(updatedBank);
    }

    [HttpPatch("{id}/positions")]
    public async Task<IActionResult> UpdatePositions(int id, [FromBody] BankPositions positions)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        
        var bank = await _bankService.UpdateBankPositionsAsync(id, positions);
        if (bank == null)
        {
            return NotFound(new { message = "Banque non trouvée" });
        }

        return Ok(bank);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        
        // Get bank details for audit log
        var bank = await _bankService.GetBankByIdAsync(id);
        if (bank == null)
        {
            return NotFound(new { message = "Banque non trouvée" });
        }

        var success = await _bankService.DeleteBankAsync(id);
        if (!success)
        {
            return NotFound(new { message = "Banque non trouvée" });
        }

        // Log the action
        await _auditService.LogAction(userId, "DELETE_BANK", "Bank", id, new
        {
            code = bank.Code,
            name = bank.Name
        });

        return NoContent();
    }

    // GET: api/banks/{bankId}/user-calibration
    [HttpGet("{bankId}/user-calibration")]
    public async Task<IActionResult> GetUserCalibration(int bankId)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        
        var positionsJson = await _bankService.GetUserCalibrationAsync(userId, bankId);
        
        return Ok(new { positionsJson = positionsJson ?? "" });
    }

    // POST: api/banks/{bankId}/user-calibration
    [HttpPost("{bankId}/user-calibration")]
    public async Task<IActionResult> SaveUserCalibration(int bankId, [FromBody] SaveCalibrationRequest request)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        var success = await _bankService.SaveUserCalibrationAsync(userId, bankId, request.PositionsJson);

        if (!success)
            return NotFound(new { message = "Utilisateur non trouvé" });

        // Log the action
        await _auditService.LogAction(userId, "UPDATE_USER_CALIBRATION", "UserCalibration", bankId, new
        {
            bankId,
            userId
        });

        return Ok(new { message = "Calibration utilisateur enregistrée" });
    }
}

public record BankCreateRequest(string Code, string Name, IFormFile? Pdf);
public record BankUpdateRequest(string? Code, string? Name, string? Positions, IFormFile? Pdf);
public record SaveCalibrationRequest(string PositionsJson);
