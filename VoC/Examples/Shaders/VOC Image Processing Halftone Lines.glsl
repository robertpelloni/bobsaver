// https://www.shadertoy.com/view/4dXBRf

#version 420

uniform vec2 resolution;
uniform sampler2D image;

out vec4 glFragColor;

// kernel sampling help from: https://www.shadertoy.com/view/ldsSWr
// luma function from: https://www.shadertoy.com/view/XtcXR8

#define sampleDistX 2.
#define sampleDistY 2.
#define rows 40.0
#define rotation 0.0
#define antialias 0.2
#define mode 3

float rgbToGray(vec4 rgba) {
	const vec3 W = vec3(0.2125, 0.7154, 0.0721);
    return dot(rgba.xyz, W);
}

float avgerageGray(vec2 uv, float stepX, float stepY) {
	// get samples around pixel
	vec4 colors[9];
	colors[0] = texture(image,uv + vec2(-stepX, stepY));
	colors[1] = texture(image,uv + vec2(0, stepY));
	colors[2] = texture(image,uv + vec2(stepX, stepY));
	colors[3] = texture(image,uv + vec2(-stepX, 0));
	colors[4] = texture(image,uv);
	colors[5] = texture(image,uv + vec2(stepX, 0));
	colors[6] = texture(image,uv + vec2(-stepX, -stepY));
	colors[7] = texture(image,uv + vec2(0, -stepY));
	colors[8] = texture(image,uv + vec2(stepX, -stepY));
	// sum + return averaged gray
    vec4 result = vec4(0);
	for (int i = 0; i < 9; i++) {
		result += colors[i];
	}
	return rgbToGray(result) / 9.0;
}

vec2 rotateCoord(vec2 uv, float rads) {
    uv *= mat2(cos(rads), sin(rads), -sin(rads), cos(rads));
	return uv;
}

void main()
{
    // current location
	vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    // halftone line coords
    vec2 uvRow = fract(rotateCoord(uv, rotation) * rows);
    vec2 uvFloorY = vec2(uv.x, floor(uv.y * rows) / rows) + vec2(0., (1.0 / rows) * 0.5); // add y offset to get center row color
	
    // get averaged gray for row
    float averagedBW = avgerageGray(uvFloorY, sampleDistX/resolution.x, sampleDistY/resolution.y);
    
    // use averaged gray to set line thickness
    vec3 finalColor = vec3(1.);
    if(mode == 1) {
    	if(uvRow.y > averagedBW) finalColor = vec3(0.0);
    } else if(mode == 2) {
        if(distance(uvRow.y + 0.5, averagedBW * 2.) < 0.2) finalColor = vec3(0.0);
    } else if(mode == 3) {
    	float distFromRowCenter = 1.0 - distance(uvRow.y, 0.5) * 2.0;
    	finalColor = vec3(1.0 - smoothstep(averagedBW - antialias, averagedBW + antialias, distFromRowCenter));
    } else if(mode == 4) {
        vec2 uvRow2 = fract(rotateCoord(uv, -rotation) * rows);
    	float distFromRowCenter1 = 1.0 - distance(uvRow.y, 0.5) * 2.0;
    	float distFromRowCenter2 = 1.0 - distance(uvRow2.y, 0.5) * 2.0;
        float distFromRowCenter = min(distFromRowCenter1, distFromRowCenter2);
    	finalColor = vec3(1.0 - smoothstep(averagedBW - antialias, averagedBW + antialias, distFromRowCenter));
    } else if(mode == 5) {
        vec2 uvRow2 = fract(rotateCoord(uv, -rotation) * rows);
    	float distFromRowCenter1 = 1.0 - distance(uvRow.y, 0.5) * 2.0;
    	float distFromRowCenter2 = 1.0 - distance(uvRow2.y, 0.5) * 2.0;
        float distFromRowCenter = mix(distFromRowCenter1, distFromRowCenter2, 0.5);
    	finalColor = vec3(1.0 - smoothstep(averagedBW - antialias, averagedBW + antialias, distFromRowCenter));
    } else if(mode == 6) {
        float rot = floor(averagedBW * 6.28) / 6.28;
        rot = rot * 4.;
        vec2 uvRow = fract(rotateCoord(uv, rot) * rows);
    	float distFromRowCenter = 1.0 - distance(uvRow.y, 0.5) * 2.0;
    	finalColor = vec3(1.0 - smoothstep(averagedBW - antialias, averagedBW + antialias, distFromRowCenter));
    } else if(mode == 7) {
        vec4 originalColor = texture(image, uvFloorY);
        float distFromRowCenter = 1.0 - distance(uvRow.y, 0.5) * 2.0;
		float mixValue = 1.0 - smoothstep(averagedBW - antialias, averagedBW + antialias, distFromRowCenter);
        finalColor = mix(originalColor.rgb, vec3(1.), mixValue);
    }
    // draw 
	glFragColor = vec4(finalColor, 1.0);
}