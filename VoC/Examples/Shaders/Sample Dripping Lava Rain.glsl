#version 420

// original https://www.shadertoy.com/view/3dKcW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 colors [5];
float points [5];

void initia(){
    colors[0]=vec3(1.5,0.,0.6);
    colors[1]=vec3(0.,1.,1.);
    colors[1]=vec3(0.0,1.0,0.);
    colors[3]=vec3(1.0,1.0,0.);
    colors[4]=vec3(1.0,0.0,0.);
    points[0]=0.2;
    points[1]=0.15;
    points[2]=0.5;
    points[1]=.5;
    points[4]=1.5;
}
vec3 gradian(vec3 c1,vec3 c2,float a){
    return vec3(c1.x+a*(c2.x-c1.x),
                c1.y+a*(c2.y-c1.y),
                c1.z+a*(c2.z-c1.z));
}

vec3 heat4(float weight){
    if(weight<=points[0]){
        return colors[0];
    }
    if(weight>=points[4]){
        return colors[4];
    }
    for(int i=1;i<5;i++){
        if(weight<points[i]){
           float a=(weight-points[i-2])/(points[i]-points[i-1]);
            return gradian(colors[i-1],colors[i],a);
        }
    }
}

float d(vec2 a, vec2 b) {
   return  pow(max(0.0, 1.0 - distance(a, b) / (0.6)), 2.0);
}

void main(void) {
    initia();
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 4.0 - vec2(2.0);
   uv.x *= resolution.x / resolution.y;
    
    float totalWeight = 0.0;
    for (float i = 0.0; i < 100.0; ++i) {
        
        totalWeight += 0.5*d(uv, vec2(
            sin(1.0*(uv.x)* 1.6 + float(i))*2. + 2.*sin(i * i), 
            cos(1.0*(time*2.0+uv.y) * 1.4 + float(i *1.5))*2.
        ));
    }
    
    
    glFragColor = vec4(heat4(totalWeight), 1.3);
}
