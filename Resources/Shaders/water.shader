shader_type spatial;

// Vectores
uniform vec2 amp = vec2(0.1, 0.1); 		// Amplitud
uniform vec2 freq = vec2(3, 5); 			// Frecuencia
uniform vec2 _time = vec2(2, 5);
// Texturas
	// ALBEDO
uniform sampler2D texmap : hint_albedo;
uniform vec2 texScale = vec2(8.0, 4.0);
	// NORMAL
uniform sampler2D texnormal : hint_normal;
	// UV
uniform sampler2D texuv : hint_black;
uniform vec2 uvScale = vec2(0.2, 0.2);
uniform float uvTimeScale = 0.05;
uniform float uvAmp = 0.2;

uniform float refraction = 0.05; // Opacidad de la refracción

float h(vec2 pos, float time) // Movimiento del agua
{
	return (amp.x * sin(pos.x * freq.x + time * _time.x)) + (amp.y * sin(pos.y * freq.y + time * _time.y));
}

void vertex()
{
	VERTEX.y += h(VERTEX.xz, TIME);
	TANGENT = normalize(vec3(0.0, h(VERTEX.xz + vec2(0.0, 0.2), TIME) - h(VERTEX.xz + vec2(0.0, -0.2), TIME), 0.4));
	BINORMAL = normalize(vec3(0.4, h(VERTEX.xz + vec2(0.2, 0.0), TIME) - h(VERTEX.xz + vec2(-0.2, 0.0), TIME), 0.0));
	NORMAL = cross(TANGENT, BINORMAL);
}

void fragment()
{
	// Ondulaciones
	// Transformación de UV
	vec2 base_uv = UV * uvScale;
	base_uv += TIME * uvTimeScale;
	vec2 texBaseOffset = texture(texuv, base_uv).rg;
	texBaseOffset = texBaseOffset * 2.0 - 1.0;
	vec2 final_texuv = UV * texScale;
	final_texuv += uvAmp * texBaseOffset;
	
	// Color
	ALBEDO = texture(texmap, final_texuv).rgb;
	if (ALBEDO.r > 0.9 && ALBEDO.g > 0.9 && ALBEDO.b > 0.9) // Transparencia
	{
		ALPHA = 0.9;
	} else {
		ALPHA = 0.5;
	}
	
	NORMALMAP = texture(texnormal, base_uv).rgb;
	METALLIC = 0.2;
	ROUGHNESS = 0.3;
	
	// Refracción
	vec3 refNormal = normalize(mix(NORMAL, TANGENT * NORMALMAP.x + BINORMAL * NORMALMAP.y + NORMAL + NORMALMAP.z, NORMALMAP_DEPTH));
	vec2 refScreen = SCREEN_UV - refNormal.xy * refraction;
	EMISSION += textureLod(SCREEN_TEXTURE, refScreen, ROUGHNESS * 8.0).rgb * (1.0 - ALPHA); // Difuminado
	
	// Aplicar ALBEDO con la transparencia
	ALBEDO *= ALPHA;
	ALPHA = 1.0;
}
