#version 420

// original https://www.shadertoy.com/view/3djSD3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 det(vec3 p3D){
     return vec2((p3D.x * 90.)/p3D.z + resolution.x/2., (p3D.y * 90.)/p3D.z + resolution.y/2.);
}

float ist(vec2 fin){
     float w = 5.;
     float r0 = 100.;
     float x = 0.;
     float y = -r0-20.;
     float z = 90.;
    
     float rate = 1.;
 
     float n = 10.;
 
    float returned = 1.;
    
    vec2 cent = det(vec3(x,y+r0*1.2,z));
    if (distance(fin,cent) > r0*1.5) {
        return 1.;
    }
    
     for (float j = 0.; j <= r0/10.; j++){
        y += 20.;
        float r = sqrt(r0*r0 - y*y);
        
        for (float i = 0.; i <= n; i++){
            vec2 dete1 = det(vec3(sin(time*rate + 6.28*i/n)*r+x-w,y-w,cos(time*rate + 6.28*i/n)*(r/2.)+z));
            vec2 dete2 = det(vec3(sin(time*rate + 6.28*i/n)*r+x+w,y+w,cos(time*rate + 6.28*i/n)*(r/2.)+z));
            
            if(fin.x > dete1.x && fin.x < dete2.x &&
               fin.y > dete1.y && fin.y < dete2.y){
                returned = min(returned,cos(time*rate + 6.28*i/n)*0.5+0.4);
            }
        }
    }
    
    return returned;
}

void main(void) {
    glFragColor = vec4(ist(gl_FragCoord.xy));
}
