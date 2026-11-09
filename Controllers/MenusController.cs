using Microsoft.AspNetCore.Mvc;
using SmartNutriTrackerAPI.DTOs;
using SmartNutriTrackerAPI.Services.Interfaces;

namespace SmartNutriTrackerAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class MenusController : ControllerBase
    {
        private readonly IMenuService _menuService;

        public MenusController(IMenuService menuService)
        {
            _menuService = menuService;
        }
        [HttpPost]
        public async Task<IActionResult> Crear([FromBody] MenuCreateDTO dto)
        {
            var nuevoMenu = await _menuService.CrearMenuAsync(dto);
            return Ok(nuevoMenu); // Cambia CreatedAtAction por Ok
        }


        [HttpPost("asignar-alimento")]
        public async Task<IActionResult> AsignarAlimento([FromBody] AsignarAlimentoDTO dto)
        {
            var asignado = await _menuService.AsignarAlimentoAMenuAsync(dto);
            return asignado ? Ok(new { Message = "Alimento asignado con éxito y resumen actualizado." }) : BadRequest();
        }

        [HttpGet("{idMenu}/resumen")]
        public async Task<IActionResult> VerResumen(int idMenu)
        {
            var resumen = await _menuService.ObtenerResumenMenuAsync(idMenu);
            return resumen != null ? Ok(resumen) : NotFound(new { Message = "Menú no encontrado." });
        }
    }
}
