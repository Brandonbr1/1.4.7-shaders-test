#version 120

/* DRAWBUFFERS:0124 */

#define POM
#define POM_MAP_RES 128.0
#define POM_DEPTH (1.0/16.0)

/* Here, intervalMult might need to be tweaked per texture pack.  
   The first two numbers determine how many samples are taken per fragment.  They should always be the equal to eachother.
   The third number divided by one of the first two numbers is inversely proportional to the range of the height-map. */
const vec3 intervalMult = vec3(1.0/16/POM_MAP_RES, 1.0/16/POM_MAP_RES, 1.0/POM_MAP_RES/POM_DEPTH); 

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform sampler2D specular;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;

varying vec3 viewVector;

varying vec3 normal;
varying vec3 tangent;
varying vec3 binormal;

varying float distance;

const float MAX_OCCLUSION_DISTANCE = 100.0;

const int MAX_OCCLUSION_POINTS = 20;

const int GL_LINEAR = 9729;
const int GL_EXP = 2048;

uniform int entityHurt;
uniform int entityFlash;
uniform int fogMode;
uniform float wetness;

void main() {
	//gl_FragData[1] = vec4(vec3(gl_FragCoord.z), 1.0);

	vec3 ambient = texture2D(lightmap, vec2(lmcoord.s,0.5/16.)).rgb + texture2D(lightmap, vec2(0.5/16., lmcoord.t)).rgb * 0.6 + (entityFlash/255.0);

	vec2 adjustedTexCoord = texcoord.st;

#ifdef POM
	if (distance <= MAX_OCCLUSION_DISTANCE && viewVector.z < 0.0) {
		vec3 coord = vec3(texcoord.st, 1.0);

		if (texture2D(normals, coord.st).a < 1.0) {
			vec2 minCoord = vec2(texcoord.s - mod(texcoord.s, 0.0625), texcoord.t - mod(texcoord.t, 0.0625));
			vec2 maxCoord = vec2(minCoord.s + 0.0625, minCoord.t + 0.0625);
		
			vec3 interval = viewVector * intervalMult;

			for (int loopCount = 0; texture2D(normals, coord.st).a < coord.z && loopCount < MAX_OCCLUSION_POINTS; ++loopCount) {
				coord += interval;
				if (coord.s < minCoord.s) {
					coord.s += 0.0625/4;
				} else if (coord.s >= maxCoord.s) {
					coord.s -= 0.0625/4;
				}
				if (coord.t < minCoord.t) {
					coord.t += 0.0625/4;
				} else if (coord.t >= maxCoord.t) {
					coord.t -= 0.0625/4;
				}
			}
		}

		adjustedTexCoord = coord.st;
	}
#endif

	vec4 diffuse = texture2D(texture, adjustedTexCoord.st) * color;
	diffuse.rgb = mix(diffuse.rgb,vec3(1.0,0.0,0.0),(entityHurt/255.0));
	vec4 texSpecular = texture2D(specular, adjustedTexCoord.st);
	vec3 bump = texture2D(normals, adjustedTexCoord.st).xyz * 2.0 - 1.0;
	
	gl_FragData[0] = vec4(mix(diffuse.rgb,vec3(1.0),(entityFlash/255.0)),diffuse.a);
	gl_FragData[3] = vec4(texSpecular.b*diffuse.rgb + vec3(texSpecular.b) + vec3(texSpecular.g)*wetness*max(lmcoord.t-(14.5/16.0),0.0), texSpecular.a);

	mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
                          tangent.y, binormal.y, normal.y,
                          tangent.z, binormal.z, normal.z);

	gl_FragData[2] = vec4(bump * tbnMatrix * 0.5 + 0.5, 1.0);


	float fogFactor;
	if (fogMode == GL_EXP) {
		fogFactor = clamp(exp(-gl_Fog.density * gl_FogFragCoord), 0.0, 1.0);
	} else if (fogMode == GL_LINEAR) {
		fogFactor = 1.0 - clamp((gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0, 1.0);
	} else {
		fogFactor = 1.0;
	}
	gl_FragData[1] = vec4(ambient, fogFactor);

//	if (fogMode == GL_EXP) {
//		gl_FragData[0].rgb = mix(gl_FragData[0].rgb, gl_Fog.color.rgb, 1.0 - clamp(exp(-gl_Fog.density * gl_FogFragCoord), 0.0, 1.0));
//	} else if (fogMode == GL_LINEAR) {
//		gl_FragData[0].rgb = mix(gl_FragData[0].rgb, gl_Fog.color.rgb, clamp((gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0, 1.0));
//	}
}