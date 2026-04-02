#version 420

// original https://www.shadertoy.com/view/McBfWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sphereSDF(vec3 p,vec3 p2){
return length(p-p2)-1.;
}

const float PI = 3.14159265f;
const float GOLDEN_ANGLE = PI * (3.0 - sqrt(5.0));

vec3 rotate(vec3 v,float a){
    mat3 matrix=mat3(vec3(cos(a),-sin(a),0.),vec3(sin(a),cos(a),0.),vec3(0.,0.,1.));

    return v*matrix;
}
//From godot
vec3 vogel_hemisphere(uint p_index, uint p_count, float p_offset) {
    float r = sqrt(float(p_index) + 0.5f) / sqrt(float(p_count));
    float theta = float(p_index) * GOLDEN_ANGLE + p_offset;
    float y = cos(r * PI * 0.5);
    float l = sin(r * PI * 0.5);
    return 20.*rotate(vec3(l * cos(theta), l * sin(theta), y * (float(p_index & 1u) * 2.0 - 1.0)),time);
}

float sampleSDF(vec3 p){
    float s=1000.;
    for(uint i=0u; i<100u; i++){
       s=min(s,sphereSDF(vogel_hemisphere(i,100u,0.),p));  
    
    }
    return s;
}

float raymarch(vec3 start, vec3 dir){
    float totaldist=0.;
    for(int i=0; i<100; i++){
        float dist=sampleSDF(start+dir*totaldist);
        if(dist<=0.05){return dist;}
        totaldist+=dist;
        
    }
    return 2000.;
    
}
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    if (raymarch(vec3(50.,-2.5,0),normalize(vec3(-1,(uv.x-0.5)*resolution.x/resolution.y,(uv.y-0.5))))<0.15){
    glFragColor = vec4(0.,0.,0.,1);
    }else{
        glFragColor = vec4(1.,1.,1.,1);
    }
    // Output to screen

}
