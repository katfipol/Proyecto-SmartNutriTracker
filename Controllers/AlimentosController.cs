using Microsoft.AspNetCore.Mvc;
using SmartNutriTrackerAPI.DTOs;
using SmartNutriTrackerAPI.Services.Interfaces;

namespace SmartNutriTrackerAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AlimentosController : ControllerBase
    {
        private readonly IAlimentoService _service;

        public AlimentosController(IAlimentoService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<IActionResult> Get() =>
            Ok(await _service.ListarAlimentosAsync());

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var al = await _service.ObtenerPorIdAsync(id);
            return al != null ? Ok(al) : NotFound(new { Message = "Alimento no encontrado." });
        }

        [HttpPost]
        public async Task<IActionResult> Post([FromBody] AlimentoCreateDTO dto)
        {
            var creado = await _service.RegistrarAlimentoAsync(dto);
            return CreatedAtAction(nameof(GetById), new { id = creado.IdAlimento }, creado);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Put(int id, [FromBody] AlimentoCreateDTO dto)
        {
            var actualizado = await _service.ActualizarAlimentoAsync(id, dto);
            return actualizado ? NoContent() : NotFound(new { Message = "No se pudo actualizar." });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var eliminado = await _service.EliminarAlimentoAsync(id);
            return eliminado ? NoContent() : NotFound(new { Message = "No se pudo eliminar." });
        }
    }
}
