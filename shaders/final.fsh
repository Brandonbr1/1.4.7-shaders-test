uniform sampler2D composite;
varying vec4 texcoord;

void main() {
	vec4 baseColor = texture2D(composite, texcoord.st);
   	gl_FragColor = baseColor;
}
