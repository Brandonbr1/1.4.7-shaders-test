#version 120

/* SHADOWRES:1024 */
/* SHADOWHPL:128 */

#define SHADOWRES 512
#define SHADOWHPL 128

/* DRAWBUFFERS:3 */

// ----------

uniform sampler2D gcolor;
//uniform sampler2D gdepth;
uniform sampler2D gnormal;
uniform sampler2D gaux1;   // specular map
//uniform sampler2D gaux2;   // ambient light
uniform sampler2D colortex1;   // ambient light
uniform sampler2D shadow;
uniform sampler2D depthtex0;

varying vec4 texcoord;
varying vec3 lightVector;
//varying vec3 specMultiplier;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform int fogMode;
uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform float sunAngle;
uniform float rainStrength;

varying vec3 heldLightSpecMultiplier;
varying float heldLightMagnitude;

const int GL_LINEAR = 9729;
const int GL_EXP = 2048;
const float PI = 3.141592653589793;

void main() {
	//gl_FragData[0] = texture2D(gcolor, texcoord.st);
	//gl_FragData[2] = texture2D(gnormal, texcoord.st);
	//gl_FragData[4] = texture2D(gaux1, texcoord.st);
	vec4 fcolor  = texture2D(gcolor, texcoord.st);
	vec4 fnormal = texture2D(gnormal, texcoord.st);
	vec4 faux1   = texture2D(gaux1, texcoord.st);
	float depth = texture2D(depthtex0, texcoord.st).x;
	vec3 normal = fnormal.xyz * 2.0 - 1.0;
	vec3 dcolor = fcolor.rgb;
	vec4 fambient = texture2D(colortex1, texcoord.st);
	vec3 ambient = fambient.rgb;
	vec4 comp;
	
	
	vec4 fragposition = gbufferProjectionInverse * vec4(texcoord.s * 2.0 - 1.0, texcoord.t * 2.0 - 1.0, 2.0 * depth - 1.0, 1.0);
	fragposition /= fragposition.w;
	vec3 npos = normalize(fragposition.xyz);

	float distance = sqrt(fragposition.x * fragposition.x + fragposition.y * fragposition.y + fragposition.z * fragposition.z);

	float shading = 1.0;

	if (distance < SHADOWHPL && distance > 0.1) {
		// shadows
		vec4 worldposition = gbufferModelViewInverse * fragposition;

		float xzDistanceSquared = worldposition.x * worldposition.x + worldposition.z * worldposition.z;
		float yDistanceSquared  = worldposition.y * worldposition.y;
		
		if (yDistanceSquared < (SHADOWHPL*SHADOWHPL*0.75)) {
			worldposition = shadowModelView * worldposition;
			float comparedepth = -worldposition.z;
			worldposition = shadowProjection * worldposition;
			worldposition /= worldposition.w;
			
			worldposition.st = worldposition.st * 0.5 + 0.5;
				
			if (comparedepth > 0.0 && worldposition.s < 1.0 && worldposition.s > 0.0 && worldposition.t < 1.0 && worldposition.t > 0.0){
				float shadowMult = clamp(1.0 - xzDistanceSquared / (SHADOWHPL*SHADOWHPL*1.0), 0.0, 1.0) * clamp(1.0 - yDistanceSquared / (SHADOWHPL*SHADOWHPL*1.0), 0.0, 1.0);
				float sampleDistance = 0.25 / SHADOWRES;
				// float shadowSample = texture2D(shadow, worldposition.st).z;
				// shadowSample = max(shadowSample, texture2D(shadow, worldposition.st + vec2( sampleDistance,  sampleDistance)).z);
				// shadowSample = max(shadowSample, texture2D(shadow, worldposition.st + vec2(-sampleDistance,  sampleDistance)).z);
				// shadowSample = max(shadowSample, texture2D(shadow, worldposition.st + vec2(-sampleDistance, -sampleDistance)).z);
				// shadowSample = max(shadowSample, texture2D(shadow, worldposition.st + vec2( sampleDistance, -sampleDistance)).z);
				float shadowSample = texture2D(shadow, worldposition.st).z;
				//shadowSample += texture2D(shadow, worldposition.st + vec2( sampleDistance,  sampleDistance)).z;
				//shadowSample += texture2D(shadow, worldposition.st + vec2(-sampleDistance,  sampleDistance)).z;
				//shadowSample += texture2D(shadow, worldposition.st + vec2(-sampleDistance, -sampleDistance)).z;
				//shadowSample += texture2D(shadow, worldposition.st + vec2( sampleDistance, -sampleDistance)).z;
				//shadowSample *= 0.25;
				float shadowDepth = 0.05 + shadowSample * (256.0 - 0.05);
				shading = 1.0 - shadowMult * clamp(comparedepth - shadowDepth - 0.1, 0.0, 1.0) * clamp(1.0 - rainStrength,0.0,1.0);
				//shading = (comparedepth <= shadowDepth)? 1.0 : 0.0;
			}
		}
	}

	if (normal==vec3(0.0) || normal==vec3(-1.0)) 
	{
		comp = vec4(dcolor * ambient,1.0);
	}
	else
	{
		//float dayTimeA = worldTime*(PI/12000);
		//float nightTimeA = dayTimeA+(PI/2);
		//float sinDayTime = sin(dayTimeA);
		vec3 specularColor = faux1.rgb;
		//vec3 sunmoonColor = vec3(max(0.3+0.5*(sinDayTime),0.2-0.2*(sinDayTime)));
		float sunmoonLevel = sin(sunAngle*(2*PI));
		if (sunmoonLevel < 0) // night
		{
			sunmoonLevel *= (-0.25);
		}
		vec3 sunmoonColor = vec3(sunmoonLevel*0.5+0.15,sunmoonLevel*0.5+0.10,sunmoonLevel*0.5+0.05);
		
		normal = normalize(normal);
		vec3 bump = reflect(npos, normal);
		float s = max(dot(bump, lightVector), 0.0);
		
		comp = vec4(min(
			dcolor * (ambient + max(dot(normal, lightVector),0.0) * sunmoonColor * shading)
			//+ specularColor * s * s * s * specMultiplier * shading
			+ specularColor * s * s * s * sunmoonColor * shading
			, 1.0), 1.0);
		
		//gl_FragData[3] = vec4(max(dot(normal, lightVector),0.0));
		
		//if (heldLightMagnitude > 0.0) {
		//	if (distance < heldLightMagnitude && distance > 0.1) {
		//		float intensity = 1.0 - min(distance / heldLightMagnitude, 1.0);
		//		s = max(dot(bump, -npos), 0.0);
		//		gl_FragData[3].rgb = min(gl_FragData[3].rgb + intensity * specularColor * s * s * s * heldLightSpecMultiplier, 1.0);
		//	}
		//}
		
		//gl_FragData[3].rgb *= shading;
	}
	
	comp.rgb = mix(comp.rgb, gl_Fog.color.rgb, 1.0-fambient.a);

	if (false) {
		float fogDepth = abs(depth);
		if (fogMode == GL_EXP) {
			comp.rgb = mix(gl_FragData[3].rgb, gl_Fog.color.rgb, 1.0 - clamp(exp(-gl_Fog.density * fogDepth), 0.0, 1.0));
		} else if (fogMode == GL_LINEAR) {
			comp.rgb = mix(gl_FragData[3].rgb, gl_Fog.color.rgb, clamp((fogDepth - gl_Fog.start) * gl_Fog.scale, 0.0, 1.0));
		} else {
			comp.rgb = mix(gl_FragData[3].rgb, gl_Fog.color.rgb, 0.5);
		}
	}
	gl_FragData[0] = comp;
}
