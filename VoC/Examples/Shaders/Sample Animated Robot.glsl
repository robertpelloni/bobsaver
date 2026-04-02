#version 420

// original https://www.shadertoy.com/view/wltcDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, -s, s, c);
}
float circle (vec2 uv, float r, float blur){
    float d = length(uv);
    return smoothstep(r,r-blur,d);
}
float DrawSquare (vec2 uv, float width, float height, float posX, float posY, float blur){
    float w = length((uv.x + posX));
    float h = length(uv.y + posY);
    float col = smoothstep(width,width-blur, w);
    col *= smoothstep(height,height-blur, h);
    return col;
}
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv-=0.5;
    uv.x *= resolution.x/resolution.y;
    
    //ray origin
    vec3 ro = vec3(0.0, 0.0, -3.0);
    
    //ray direction
    vec3 rd = vec3(uv.x,uv.y, 0)-ro;
    
    // Time varying pixel color
    float width = 0.3;
    float height = 0.3;
    float blur = 0.01;
    float posX = 0.;
    float posY = -0.;
    
    float head = DrawSquare(uv, width, height, posX, posY, blur);
    head += DrawSquare(uv, width * 0.5, height * 0.15, posX, posY + 0.335, blur);
    head += DrawSquare(uv, width * 2., height, posX, posY + 0.67, blur);
    vec3 img = vec3(.8) * head;
    //outer eyes
    float Reye = DrawSquare(uv, width * 0.2, height * (sin(time)*0.05 +0.15), posX + 0.15, posY-0.1, blur);
    
    img -= vec3(1.,1.,1.) * Reye;
    
    float Leye = DrawSquare(uv, width * 0.2, height * 0.2, posX - 0.15, posY-0.1, blur);
    
    img -= vec3(1.,1.,1.) * Leye;
    
    //inner eyes
    float RIeye = DrawSquare(uv, width * 0.1, height * 0.1, posX + 0.15, posY-0.1, blur);
    
    img += vec3(smoothstep(1.,0.9,sin(time)),0.,0.) * RIeye;
    
    float LIeye = DrawSquare(uv, width * 0.1, height * 0.1, posX - 0.15, posY-0.1, blur);
    
    img += vec3(1.,smoothstep(smoothstep(1.,0.9,cos(time*5.)),0.9,sin(time*5.)),smoothstep(1.,0.9,sin(time*5.))) * LIeye;
    
    //mouth
    float mouth = DrawSquare(uv, width * 0.5, height * 0.2, posX, posY+0.15, blur);
    img -= vec3(1.,1.,1.) * mouth;
    
    //mouth inner
    float mouthI = DrawSquare(uv, width * 0.48, height * (sin(time*3.)*0.04+0.14), posX, posY+0.15, blur);
    img += vec3(0.,1.,1.) * mouthI;
    
    //mouth slats
    float mouthS = DrawSquare(uv, width * 0.05, height * 0.18, posX, posY+0.15, blur);
    mouthS += DrawSquare(uv, width * 0.05, height * 0.18, posX-.05, posY+0.15, blur);
    mouthS += DrawSquare(uv, width * 0.05, height * 0.18, posX-.1, posY+0.15, blur);
    mouthS += DrawSquare(uv, width * 0.05, height * 0.18, posX+.05, posY+0.15, blur);
    mouthS += DrawSquare(uv, width * 0.05, height * 0.18, posX+.1, posY+0.15, blur);
    img -= vec3(0.,1.,1.) * mouthS;
    
    //nose
    vec2 rotUV = uv * rotate(time);
    float nose = circle (rotUV, 0.03, blur);
    nose += DrawSquare(rotUV, width * 0.03, height * 0.09, posX, posY, blur);
    nose += DrawSquare(rotUV, width * 0.09, height * 0.03, posX, posY, blur);
    img -= vec3(.5,.5,.5) * nose;
    
    //screws
    float screws = circle (uv - vec2(0.25), 0.03, blur);
    screws += DrawSquare(uv, width * 0.03, height * 0.09, posX - 0.25, posY - 0.25, blur);
    screws += DrawSquare(uv, width * 0.09, height * 0.03, posX - 0.25, posY - 0.25, blur);
    
    screws += circle (uv - vec2(-0.25), 0.03, blur);
    screws += DrawSquare(uv, width * 0.03, height * 0.09, posX + 0.25, posY + 0.25, blur);
    screws += DrawSquare(uv, width * 0.09, height * 0.03, posX + 0.25, posY + 0.25, blur);
    
    screws += circle (uv - vec2(-0.25, 0.25), 0.03, blur);
    screws += DrawSquare(uv, width * 0.03, height * 0.09, posX + 0.25, posY - 0.25, blur);
    screws += DrawSquare(uv, width * 0.09, height * 0.03, posX + 0.25, posY - 0.25, blur);
    
    screws += circle (uv - vec2(0.25, -0.25), 0.03, blur);
    screws += DrawSquare(uv, width * 0.03, height * 0.09, posX - 0.25, posY + 0.25, blur);
    screws += DrawSquare(uv, width * 0.09, height * 0.03, posX - 0.25, posY + 0.25, blur);
    img -= vec3(.5,.5,.5) * screws;
    // Output to screen
    glFragColor = vec4(img,1.0);
}
