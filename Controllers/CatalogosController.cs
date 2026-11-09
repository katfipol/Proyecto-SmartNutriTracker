using Microsoft.AspNetCore.Mvc;
using SmartNutriTrackerAPI.Services.Interfaces;

namespace SmartNutriTrackerAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CatalogosController : ControllerBase
    {
        private readonly ICatalogoService _service;

        public CatalogosController(ICatalogoService service)
        {
            _service = service;
        }

        [HttpGet("categorias")]
        public async Task<IActionResult> GetCategorias() =>
            Ok(await _service.ListarCategoriasAsync());

        [HttpGet("tiempos-comida")]
        public async Task<IActionResult> GetTiemposComida() =>
            Ok(await _service.ListarTiemposComidaAsync());
    }
}
