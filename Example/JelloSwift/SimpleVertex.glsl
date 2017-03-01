attribute vec4 Position;
attribute vec4 SourceColor;

uniform mat4 mvp;

varying vec4 DestinationColor;

void main(void) {
	DestinationColor = SourceColor;
	gl_Position = mvp * Position;
}
