#version 420

// original https://www.shadertoy.com/view/mt3BzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rotationSpeed = 0.1;
float gridWidth = 0.025;

// f should take a 2d coordinate and return a value between 0 and `functionMax`
// if the magnitude of the gradient is greater than the viewing angle there may be visual 
// artifacts
// The visible coordinates are approximately [-scale, scale]

// offset 5x modulated 2d sin
/*
float scale = 16.0;
float functionMax = 1.0;
float f(vec2 xy) {
    float z = (sin(3.14*4.0*sin(time - 0.2*distance(xy, vec2(-1,0)))) + 1.0)/2.0 +
              (sin(3.14*4.0*sin(time - 0.2 - 0.2*distance(xy, vec2(+0,0)))) + 1.0)/2.0 +
              (sin(3.14*4.0*sin(time - 0.4 - 0.2*distance(xy, vec2(+1,0)))) + 1.0)/2.0 +
              (sin(3.14*4.0*sin(time - 0.6 - 0.2*distance(xy, vec2(+2,0)))) + 1.0)/2.0 +
              (sin(3.14*4.0*sin(time - 0.8 - 0.2*distance(xy, vec2(+3,0)))) + 1.0)/2.0;
    z/=5.0;
    return z;
}
*/

// modulated 2d sin
float scale = 10.0;
float functionMax = 1.0;
float f(vec2 xy) {
    float z = (sin(3.14*4.0*sin(time - 0.2*length(xy))) + 1.0)/2.0;
    return z;
}

/*
// 2d sin
float scale = 8.0;
float functionMax = 1.0;
float f(vec2 xy) {
    float z = (sin(length(xy*2.0) - time) + 1.0)/2.0;
    return z;
}

// static 2d gaussian
float scale = 2.0;
float functionMax = 1.0;
float f(vec2 xy) {
    float z = exp(-length(xy)*length(xy));
    return z;
}
*/

// step is theoretically the difference in pos between two adjacent pixels, if you
// want to anti-alias a hard edge. Practically, it's linear blur radius
float lineAlpha(float pos, float step_, float lineWidth) {
    pos = fract(pos);
    float scale = step_;
    float rem = pos + step_ - 1.0;
    if (rem > 0.0) {
        step_ = rem;
        pos = 0.0;
    }
        
    return min(max(lineWidth - pos, 0.0), step_) / scale;
}

// draw grid with blur
float lookupColor(vec2 xy, float gridScale) {
    float lineWidth = 0.1;
    xy /= gridWidth*gridScale;
    
    // theoretically, the step value should be determined by the slope at point of
    // intersection. Because it's fixed instead the result is a flat look, as if this
    // was a texture. This can also lead to aliasing.
    float step_ = 0.1;

    float lineAlphaX = lineAlpha(xy.x, step_, lineWidth);
    float lineAlphaY = lineAlpha(xy.y, step_, lineWidth);
    return lineAlphaX * (1.0-lineAlphaY) + lineAlphaY;
}

void main(void) {
    vec2 uv = scale*(gl_FragCoord.xy - resolution.xy / 2.0)/resolution.y;
    
    vec3 camera = vec3(sin(time * rotationSpeed),1.5,cos(time * rotationSpeed));
    vec3 lookAt = vec3(0.0,0.0,0.0);
    vec3 up = vec3(0.0,1.0,0.0);

    vec3 lookDir = lookAt - camera;
    vec3 cameraX = normalize(cross(lookDir, up));
    vec3 cameraY = normalize(cross(cameraX, lookDir));
    
    // scale camera location to make sure the view plane doesn't clip the function
    camera = camera * (functionMax + 0.5*scale*cameraY.y) / camera.y;
    
    
    // binary search based zero finding for function assuming function is non-negative
    // this potentially skips over the first intersection
    // works best if the slope of the function is less than the slope of look dir
    
    // orthographic perspective using lookdir
    vec3 uvInWorldSpace = camera + uv.x*cameraX + uv.y*cameraY;
    float maxStep = uvInWorldSpace.y / lookDir.y;
    vec3 step_ = maxStep * lookDir * 0.5;
    vec3 pos = uvInWorldSpace;

    // lower numbers are 'blocky', higher is slower, but smooth.
    // 12 or so looks completely smooth
    int depth = 12;
    
    for (int i = 0; i < depth; i++) {
        
        if (f(pos.xz) - pos.y > 0.0) {
            pos += step_;
        } else {
            pos -= step_;
        }
        step_ *= 0.5;
    }
    
    
    glFragColor = vec4(lookupColor(pos.xz, scale));
    // glFragColor = vec4(pos.y);
    glFragColor = (pos.y/functionMax*0.8 + 0.2)*vec4(lookupColor(pos.xz, scale));
}
