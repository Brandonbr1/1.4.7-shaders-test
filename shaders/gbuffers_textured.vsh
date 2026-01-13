#version 120

varying vec4 color;
varying vec4 texcoord;
varying vec3 normal;
varying float distance;

void main() {
	vec4 position = gl_ModelViewMatrix * gl_Vertex;
	distance = sqrt(position.x * position.x + position.y * position.y + position.z * position.z);
	
	gl_Position = ftransform();
	
	color = gl_Color;
	
	texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;
	
	normal = gl_Normal;

	//gl_FogFragCoord = gl_Position.z;
	gl_FogFragCoord = distance;
}