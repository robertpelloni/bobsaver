#version 420

// original https://www.shadertoy.com/view/WtKGDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float n11(float p) {
    return fract(sin(p*154.101)*313.019);
} 
float n21(vec2 p) {
    float n = sin(dot(p, vec2(7, 157)));    
    return n;
}
vec3 hash33(vec3 p){ 
    float n = sin(dot(p, vec3(7, 157, 113)));    
    return fract(vec3(2097152, 262144, 32768)*n); 
}

float voronoi(vec3 p){

    vec3 b, r, g = floor(p);
    p = fract(p);
    float d = 1.; 
    for(int j = -1; j <= 1; j++) {
        for(int i = -1; i <= 1; i++) {
            
            b = vec3(i, j, -1);
            r = b - p + hash33(g+b);
            d = min(d, dot(r,r));
            
            b.z = 0.0;
            r = b - p + hash33(g+b);
            d = min(d, dot(r,r));
            
            b.z = 1.;
            r = b - p + hash33(g+b);
            d = min(d, dot(r,r));
                
        }
    }
    
    return d; // Range: [0, 1]
}

vec3 hsl2rgb( in vec3 c ){
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0,1.0);
    return c.z + c.y * (rgb-0.5)*(1.0-abs(2.0*c.z-1.0));
}

float nebula(in vec3 p) {
    float amp = 1., sum=0., z= 1., m = 0.;
    for(int i=1; i<=10;i++){
        vec3 t = vec3(0., 0., p.z+time*.1);
        z *= 2.;
        m += voronoi(vec3(p.xy*z, 1.)+t) *amp;
        sum += amp;
        amp *= .5;
    }
    m /= sum;
    return pow(m, 1.5);
}

float star(vec3 p) {
    float z = 16.;
    float t = p.z;
    vec2 gv = fract(p.xy*z)-.5;
    vec2 id = floor(p.xy*z);
    gv.x += sin(n21(id)*354.23)*.3;
    gv.y += sin(n11(n21(id))*914.19)*.3;
    float r = n11(n21(id));
    float m =  .1*n11(r)*abs(sin(p.z+r*133.12))/length(gv)*.1;
    return m;
}

float stars(in vec3 p) {
    float amp = 1., sum=0., z= 1., m = 0.;
    for(int i=1; i<=5;i++){
        vec3 t = vec3(0., 0., p.z+time*.2);
        z *= 2.;
        m += star(vec3(p.xy*z, 1.)+t) *amp;
        sum += amp;
        amp *= .5;
    }
    m /= sum;
    return m;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0.);
    
    vec3 col1 = normalize(vec3(159., 38., 106.))*nebula(vec3(uv,1.));
    vec3 col2 = normalize(vec3(106., 110., 185.))*nebula(vec3(uv,1298.));
    col = mix(col1,col2,5.);
    float m = stars(vec3(uv, time*2.));
    col += vec3(m);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
