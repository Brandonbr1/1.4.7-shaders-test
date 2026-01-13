#version 120

/* DRAWBUFFERS:0124 */

uniform sampler2D texture;
uniform sampler2D lightmap;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec3 normal;

void main() {
	vec3 ambient = texture2D(lightmap, lmcoord.st).rgb;
	gl_FragData[0] = texture2D(texture, texcoord.st) * color;
	//gl_FragDepth = gl_FragCoord.z;
	gl_FragData[2] = vec4(normal * 0.5 + 0.5, 1.0);
	gl_FragData[3] = vec4(0.0, 0.0, 0.0, 1.0);
	gl_FragData[1] = vec4(ambient, 1.0);
}
