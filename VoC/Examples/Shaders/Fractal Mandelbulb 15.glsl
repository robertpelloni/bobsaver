#version 420

// original https://www.shadertoy.com/view/4s2fRW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 obj_union(in vec2 obj0, in vec2 obj1)
{
      if (obj0.x < obj1.x)
          return obj0;
      else
        return obj1;
}

vec2 obj_floor(in vec3 p)
{
    return vec2(p.y+4.0,0);
}

vec2 obj_mandel(in vec3 p, in float power)
{
    vec3 z = p;
    float dr = 1.0;
    float r = 0.0;
    for (int i = 0; i < 10 ; i++) {
        r = length(z);
        if (r>4.0) break;
        
        float theta = acos(z.z/r);
        float phi = atan(z.y,z.x);
        dr =  pow(r, power-1.0)*power*dr + 1.0;
        
        float zr = pow(r, power);
        theta = theta*power;
        phi = phi*power;
        
        z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        z+=p;
    }
    return vec2(0.5*log(r)*r/dr, 1.0);
}

vec2 distance_to_obj(in vec3 p)
{
    float power = (sin(time * 0.1) + 1.0) * 0.5 * 10.0 + 1.0;
      return obj_union(obj_floor(p), obj_mandel(p / 3.0, power));
}

float shadowSoft( vec3 ro, vec3 rd, float mint, float maxt, float k )
{
    float t = mint;
    float res = 1.0;
    for ( int i = 0; i < 64; ++i )
    {
        vec2 h = distance_to_obj( ro + rd * t );
        if ( h.x < 0.001 )
            return 0.1;
        
        res = min( res, k * h.x / t );
        t += h.x;
        
        if ( t > maxt )
            break;
    }
    return res;
}

float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = distance_to_obj( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}

vec3 floor_color(in vec3 p)
{
    float f = mod(floor(p.z / 3.0) + floor(p.x / 3.0), 2.0);
    return 0.3 + 0.1 * f * vec3(1.0);
}

vec3 prim_c(in vec3 p)
{
      return vec3(0.8,0.8,0.8);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 vPos = -1.0 + 2.0 * uv;

       vec3 vuv=vec3(0,1,0); 
    vec3 vrp=vec3(0,0,0);

    vec3 prp = vec3(sin(time*0.15) * 4.0,2.0,cos(time*0.15) * 4.0); 
    
    vec3 vpn = normalize(vrp-prp);
      vec3 u = normalize(cross(vuv,vpn));
      vec3 v = cross(vpn,u);
      vec3 vcv = (prp+vpn);
      vec3 scrCoord = vcv+vPos.x*u*resolution.x/resolution.y+vPos.y*v;
      vec3 scp = normalize(scrCoord-prp);
    
    vec3 lightPos = vec3(sin(time * 0.5) * 7.0, 3.0, -cos(time * 0.5) * 7.0);
      vec3 fogColor = vec3(0.5,0.6,0.7);
    vec3 lightColor = vec3(0.8);

    const vec3 e = vec3(0.02,0,0);
      const float maxd = 100.0;
      vec2 d = vec2(0.02,0.0);
      vec3 c,p,N;
    
    float f = 1.0;
    float stepDist = 0.9;
    for(int i = 0; i < 256; i++)
    {
         if((abs(d.x) < .001) || (f > maxd))
            break;
        f += d.x;
        p = prp + scp * f;
        d = distance_to_obj(p);
    }
    
    if (f < maxd)
      {
        if (d.y==0.0) {
              c=floor_color(p);
            N = vec3(0.0, 1.0, 0.0);
        } else {
              c=prim_c(p);
            N = vec3(d.x-distance_to_obj(p-e.xyy).x, d.x-distance_to_obj(p-e.yxy).x, d.x-distance_to_obj(p-e.yyx).x);
        }
        
        N = normalize(N);
        vec3 lightDir = normalize(lightPos - p);
        float diff = max(dot(N, lightDir), 0.0);
        vec3 diffuse = 0.3 + diff * lightColor; 
        float vis = shadowSoft( p, normalize(lightPos-p), 0.0625, length(lightPos-p), 128.0 );
        float ambient = 0.15;
        float ao = calcAO(p, N);
        
        float fogAmount = 1.0 - exp(-sqrt(p.x * p.x + p.z * p.z) * 0.035 );
        glFragColor = vec4(mix(c * diffuse * (ao * 1.0) * (vis + 1.3) + ambient, fogColor, fogAmount), 1.0);
  }
  else 
    glFragColor = vec4(fogColor,1);
    
}
