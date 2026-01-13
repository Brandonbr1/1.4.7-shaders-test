#version 120

varying vec4 color;
varying vec3 normal;

void main() {
	gl_Position = ftransform();
	
	color = gl_Color;
	
	normal = gl_Normal;

	vec4 position = gl_ModelViewMatrix * gl_Vertex;
	float distance = sqrt(position.x * position.x + position.y * position.y + position.z * position.z);
	gl_FogFragCoord = distance;
	//gl_FogFragCoord = gl_Position.z;
}