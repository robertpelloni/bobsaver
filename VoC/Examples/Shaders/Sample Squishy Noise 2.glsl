#version 420

// original https://www.shadertoy.com/view/ttGczm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//<3d simplex noise by nikat https://www.shadertoy.com/view/XsX3zB>
vec3 random3(vec3 c) {
    float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
    vec3 r;
    r.z = fract(512.0*j);
    j *= .125;
    r.x = fract(512.0*j);
    j *= .125;
    r.y = fract(512.0*j);
    return r-0.5;
}

/* skew constants for 3d simplex functions */
const float F3 =  0.3333333;
const float G3 =  0.1666667;

/* 3d simplex noise */
float simplex3d(vec3 p) {
     /* 1. find current tetrahedron T and it's four vertices */
     /* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
     /* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/

     /* calculate s and x */
     vec3 s = floor(p + dot(p, vec3(F3)));
     vec3 x = p - s + dot(s, vec3(G3));

     /* calculate i1 and i2 */
     vec3 e = step(vec3(0.0), x - x.yzx);
     vec3 i1 = e*(1.0 - e.zxy);
     vec3 i2 = 1.0 - e.zxy*(1.0 - e);

     /* x1, x2, x3 */
     vec3 x1 = x - i1 + G3;
     vec3 x2 = x - i2 + 2.0*G3;
     vec3 x3 = x - 1.0 + 3.0*G3;

     /* 2. find four surflets and store them in d */
     vec4 w, d;

     /* calculate surflet weights */
     w.x = dot(x, x);
     w.y = dot(x1, x1);
     w.z = dot(x2, x2);
     w.w = dot(x3, x3);

     /* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
     w = max(0.6 - w, 0.0);

     /* calculate surflet components */
     d.x = dot(random3(s), x);
     d.y = dot(random3(s + i1), x1);
     d.z = dot(random3(s + i2), x2);
     d.w = dot(random3(s + 1.0), x3);

     /* multiply d by w^4 */
     w *= w;
     w *= w;
     d *= w;

     /* 3. return the sum of the four surflets */
     return dot(d, vec4(52.0));
}
//</3d simplex noise by nikat https://www.shadertoy.com/view/XsX3zB>
float fbm(vec2 xy, float z, int octs){
    float f = 1.0;
    float a = 1.0;
    float t = 0.0;
    float a_bound = 0.0;
    for(int i=0;i<octs;i++){
        t += a*simplex3d(vec3(xy*f,z*f));
        f *= 2.0;
        a_bound += a;
        a *= 0.5;
    }
    return t/a_bound;
}
float noise_final_comp(vec2 xy, float z){
    float value = fbm(vec2(xy.x / 200.0+513.0, xy.y / 200.0+124.0), z, 3);
    value = 1.0-abs(value);
    value = value*value;
    return value*2.0-1.0;
}
float noise_f(vec2 xy, float z){
        float value = fbm(
            vec2((noise_final_comp(xy,       z)*15.0+xy.x) / 100.0,
                 (noise_final_comp(xy+300.0, z)*15.0+xy.y) / 100.0), z*1.5, 5);
                 
        return max(0.0, min(1.0, (value*0.5+0.5)*1.3));
}
float noise_a(vec2 xy, float z){
        float value = fbm(
            vec2((xy.x) / 100.0,
                 (xy.y) / 100.0), z*1.5, 1);
                 
        return max(0.0, min(1.0, (value*0.5+0.5)*1.3));
}
float noise_b(vec2 xy, float z){
        float value = fbm(
            vec2((xy.x) / 100.0,
                 (xy.y) / 100.0), z*1.5, 2);
                 
        return max(0.0, min(1.0, (value*0.5+0.5)*1.3));
}
vec2 noise_c(vec2 xy, float z){
        vec2 value = 
            vec2((noise_final_comp(xy,       z)*15.0),
                 (noise_final_comp(xy+300.0, z)*15.0));
        value.x = max(0.0, min(1.0, (value.x*0.5+0.5)/10.0));    
        value.y = max(0.0, min(1.0, (value.y*0.5+0.5)/10.0));    
        return value;
}
float noise_e(vec2 xy, float z){
        float value = fbm(
            vec2((xy.x) / 100.0,
                 (xy.y) / 100.0), z*1.5, 5);
                 
        return max(0.0, min(1.0, (value*0.5+0.5)*1.3));
}
void main(void) {
    vec2 uv = gl_FragCoord.xy*500.0/resolution.x;

    float pA = noise_a(uv,time*0.025+0.05*sin(time*0.2+(uv.x*0.3*(sin(time/30.0)-0.3)+uv.y)/265.0));
    float pB = noise_b(uv,time*0.025+0.05*sin(time*0.2+(uv.x*0.3*(sin(time/30.0)-0.3)+uv.y)/265.0));
    vec2  pC = noise_c(uv,time*0.025+0.05*sin(time*0.2+(uv.x*0.3*(sin(time/30.0)-0.3)+uv.y)/265.0));
    float pE = noise_e(uv,time*0.025+0.05*sin(time*0.2+(uv.x*0.3*(sin(time/30.0)-0.3)+uv.y)/265.0));
    float pF = noise_f(uv,time*0.025+0.05*sin(time*0.2+(uv.x*0.3*(sin(time/30.0)-0.3)+uv.y)/265.0));
    
    vec3 c1 = vec3(152.0,193.0,217.0)/255.0;
    vec3 c2 = vec3(224.0,251.0,252.0)/255.0;
    vec3 c3 = vec3(238.0,108.0,77.0)/255.0;
    vec3 c4 = vec3(41.0,50.0,65.0)/255.0;
    
    
    // Mouse code based (loosely) from iq (https://www.shadertoy.com/view/4djSDy)
    float s = (2.0*mouse.x*resolution.xy.x-resolution.x) / resolution.y;
    //s=1.0;
    
    float sAB=step((8.0  *gl_FragCoord.xy.x-resolution.x) / resolution.y-s,0.0);
    float sBC=step((4.0  *gl_FragCoord.xy.x-resolution.x) / resolution.y-s,0.0);
    float sCE=step((2.685*gl_FragCoord.xy.x-resolution.x) / resolution.y-s,0.0);
    float sEF=step((2.0  *gl_FragCoord.xy.x-resolution.x) / resolution.y-s,0.0);
    float p =pA*sAB+pB*(1.0-sAB)*sBC+pE*(1.0-sCE)*sEF+pF*(1.0-sEF);
    vec3 col = clamp(p*1.5-0.75,0.0,1.0)*1.0*c2+(1.0-clamp(abs(p-0.5)*5.0,0.0,1.0))*c3;
    
    col+=(pC.x*c1+pC.y*c4)*(1.0-sBC)*sCE;
    
    vec2 rC = vec2(max(resolution.x,resolution.y),
                   min(resolution.x,resolution.y));
                   
    glFragColor = vec4(col,p*clamp(1.3-1.5*length(gl_FragCoord.xy-0.5*vec2(rC.x,rC.y))/rC.y,0.0,1.0));
}
