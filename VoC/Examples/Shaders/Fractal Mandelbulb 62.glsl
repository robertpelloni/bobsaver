#version 420

// original https://www.shadertoy.com/view/ftjXWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sph(in vec3 pos, in vec3 cen, in float r) {
    return length(pos - cen) - r; 
}

float plane(in vec3 pos, in float r) {

    return pos.y - (-r);
}
float mnd(in vec3 pos) {
    vec3 z = pos;
    float dr = 2.0;
    float r = 0.0;
    
    for(int i = 0; i < 200; i++) {
        
        r = length(z);
        
        if (r >= 2.0 ) {
            break;
        }
        
        float power = 9.0; //abs(6.0 *sin(time * 0.1)) + 2.0;
        
        float theta = acos(z.z / r);
        float phi = atan(z.y, z.x);
        
        dr = pow(r, power - 1.0 ) * power * dr + 1.0;
        
        float zr = pow(r, power);
        theta = theta * power;
        phi = phi * power;
        
        z = zr * vec3(sin(theta) * cos(phi),
                      sin(phi) * sin(theta),
                      cos(theta));
        z += pos;
    }
    
    return 0.5 * log(r) * r / dr;
}

vec2 mmin(in vec2 a, in vec2 b) {
    
    return abs(a.x) < abs(b.x) ? a: b;
}

vec2 map(in vec3 pos) {
    
    vec2 d1 = vec2(mnd(pos), 1.0);
    
    vec2 d2 = vec2(sph(pos, vec3(0.0), 700.0), 2.0);
    
    return mmin(d1, d2);
}

vec3 normal(in vec3 pos)
{
    const vec3 eps = vec3(0.001, 0.0, 0.0);
        
    float grad_x = map(pos + eps.xyy).x - map(pos - eps.xyy).x;
    float grad_y = map(pos + eps.yxy).x - map(pos - eps.yxy).x;
    float grad_z = map(pos + eps.yyx).x - map(pos - eps.yyx).x;
  
    return normalize(vec3(grad_x, grad_y, grad_z));
}

vec2 rayMarch(in vec3 ro, in vec3 rd) 
{

    float t = 0.0; 
    float d = 0.0; 
    
    for(int i = 0; i < 200; i++){
    
        vec2 pos = map(ro + t* rd); 
        
        if(pos.x < 0.001){
            
            pos.x = t; 
               
            return pos;
        } 
        
        if(pos.x > 1000.0){
            break;
        }
        
        t += pos.x;
    }
    
    return vec2(-1.0);

}

float diffuse_light(in vec3 pos, in vec3 cen){
    
    vec3 nor = normal(pos);
    vec3 dir_to_light = normalize(cen-pos);
    float diff_intens = dot(nor, dir_to_light);
    
    return diff_intens;

}

float phong_light(in vec3 pos, in vec3 cen, in vec3 ro, in float k){
    
    float specPower = k;
    vec3 n = normal(pos);
    vec3 l = normalize(cen-pos);
    vec3 v = normalize(ro-pos);
    vec3 r = reflect(-v, n);
    float phong_light = pow ( max ( dot ( l, r ), 0.0 ), specPower );
    return phong_light;

}

float shadow(vec3 pos, vec3 lightpos){
    vec3 rd = normalize(lightpos-pos);
    float res = 1.0;
    float t = 0.0;
    
    for (float i = 0.0; i < 100.0; i++)
    {
        vec2 h = map(pos + rd * t);
        res = min(res, 200.0 * h.x / t);
        t += h.x;
        
        if ((res < 0.0001 || t > 320.0)) break;
        
    }
    
    return clamp(res, 0.0, 1.0);
    
}

vec3 mnd2D(in vec2 C){
    vec2 z = vec2(0.0 , 0.0);
    float n = .0;
    while (length(z) <= abs(20.0 * sin(time*0.5))+1.0 && n < abs(20.0 * sin(time*0.5))+1.0){
        z = vec2(z.x * z.x -  z.y * z.y,  2.0 * z.x * z.y) + C;
        n += 1.0;
    }
    return vec3(n / (abs(20.0 * sin(time*0.1))+1.0));
}
float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.01 + 0.15*float(i)/5.0;
        float d = map( pos + h*nor ).x;
        occ += (h-d)*sca;
        sca *= 0.95;
        if( occ>0.35 ) break;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 ) * (0.5+0.5*nor.y);
}

vec3 render(in vec3 ro, in vec3 rd){
    
    vec2 h = rayMarch(ro, rd);
    vec3 col = vec3(1.0,1.0,1.0);
    vec3 pos = ro + h.x * rd;
    if (h.y == 1.0) {
        
        //col *= phong_light(pos, vec3(50.0*sin(time), 200.0, cos(time)), ro, 20.5) * vec3(1.0,1.0,1.0);
        //col *= diffuse_light(pos, vec3(50.0*sin(time), 200.0, cos(time))) * vec3(1.3, 1.3, 1.3);
        col *= calcAO(pos, normal(pos)) * vec3(1.9);
        
        return col;
    }
    else if (h.y == 2.0){
    
    
       
        vec3 n_pos = normalize(pos);
        vec2 C =  vec2(-n_pos.x - n_pos.z -n_pos.y + sin(time * 0.5),-n_pos.x - n_pos.z +n_pos.y + cos(time * 0.5));
        col *= vec3(1.0) - mnd2D(C);
    
        //col *= diffuse_light(pos, vec3(50.0, 200.0, 1.0)) * vec3(0.2, 0.2, 0.1);
        //col *= shadow(pos, vec3(50.0*sin(time), 200.0, cos(time)));
        return col;
        
    }
    
    return vec3(0.0);
    
        
}

void main(void)
{
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy)/resolution.y;
    
    float an = time * 0.1;//10.0 * mouse*resolution.xy.x/resolution.x;
    
    vec3 ro = vec3(1.0*cos(an)*1.5, 1.3*sin(time*0.05), 1.0*sin(an) * 1.5);
    vec3 ta = vec3(0.0); // target for camera

    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize( cross(ww, vec3(0,1,0)));
    vec3 vv = normalize( cross(uu, ww));

    vec3 rd = normalize(uv.x*uu + uv.y*vv + ww);
    vec3 col = render(ro, rd); 
    
    glFragColor = vec4(col,1.0);
}
