// https://www.shadertoy.com/view/XdfGDH

#version 400

uniform vec2 resolution;
uniform sampler2D image;

out vec4 glFragColor;

float normpdf(in float x, in float sigma)
{
	return 0.39894*exp(-0.5*x*x/(sigma*sigma))/sigma;
}

void main(void) {
	vec2 uv = (gl_FragCoord.xy/resolution.xy);
	//declare stuff
	const int mSize = 3;
	const int kSize = (mSize-1)/2;
	float kernel[mSize];
	vec3 final_colour = vec3(0.0);
		
	//create the 1-D kernel
	float sigma = 7.0;
	float Z = 0.0;
	for (int j = 0; j <= kSize; ++j)
	{
		kernel[kSize+j] = kernel[kSize-j] = normpdf(float(j), sigma);
	}
		
	//get the normalization factor (as the gaussian has been clamped)
	for (int j = 0; j < mSize; ++j)
	{
		Z += kernel[j];
	}
		
	//read out the texels
	for (int i=-kSize; i <= kSize; ++i)
	{
		for (int j=-kSize; j <= kSize; ++j)
		{
			final_colour += kernel[kSize+j]*kernel[kSize+i]*texture(image, (gl_FragCoord.xy+vec2(float(i),float(j))) / resolution.xy).rgb;
		}
	}
	glFragColor = vec4(final_colour/(Z*Z), 1.0);
}