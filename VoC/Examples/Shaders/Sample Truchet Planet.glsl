#version 420

// original https://www.shadertoy.com/view/WdlyRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//to do:

// mode = 0. for a convenient environment to develop
// mode = 1. for a regular environment
# define mode 1.

# define MaxSteps 100
# define MaxDist 20.

vec3 pow3(vec3 a, float b)
{
    return vec3(pow(a.x,b), pow(a.y,b), pow(a.z,b));
}
mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}
vec3 RotX (vec3 p, float speed)
{   
    float ss = sin(speed), cc = cos(speed);
    return vec3(p.x, p.y*cc + p.z*-ss,  p.y*ss + p.z*cc);
}
vec3 RotY (vec3 p, float speed)
{   
    float ss = sin(speed), cc = cos(speed);
    return vec3(p.x*cc + p.z*ss, p.y, p.x*-ss + p.z*cc);
}
vec3 RotZ (vec3 p, float speed)
{   
    float ss = sin(speed), cc = cos(speed);
    return vec3(p.x*cc  + p.y*-ss, p.x*ss + p.y*cc, p.z);
}
float opUS( float d1, float d2, float k ) 
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    float dist = mix( d2, d1, h ) - k*h*(1.0-h); 
     return dist;
}
vec4 opUS( vec4 d1, vec4 d2, float k ) 
{
    float h = clamp( 0.5 + 0.5*(d2.w-d1.w)/k, 0.0, 1.0 );
    vec3 color = mix(d2.xyz, d1.xyz, h);
    float dist = mix( d2.w, d1.w, h ) - k*h*(1.0-h); 
     return vec4(color, dist);
}
float opSS( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); }
float opSI( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h); }
vec4 min2(vec4 d1, vec4 d2)
{
    return min(d1.w,d2.w) == d1.w ? d1 : d2;
}
float sdBox(vec3 p, vec3 s) 
{
  vec3 q = abs(p) - s;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
float sdRoundBox( vec3 p, vec3 s, float r )
{
  vec3 q = abs(p) - s;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}
float sdCylinder( vec3 p, vec3 c )
{
  return length(p.xz-c.xy)-c.z;
}
float sdCapsule( vec3 p, float h, float r )
{
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}
vec2 GetSphereUV(vec3 p, float r)
{
    vec3 n = normalize(p);
    float x = atan(n.x, n.z);///(2.*PI) + 0.5;
    float y = n.y;//0.5 + 0.5*n.y;
    return vec2(x,y);
}
float sdSphere( vec3 p, float r) {
    float d =  length(p) - r;
    return d;
}

float PI = acos(-1.); //3.141592654;
vec2 UVPIMUL = vec2(2., 1.)*2.;
vec2 UVPIADD = vec2(0., 0.);   
vec2 UVMUL = vec2(7., 6.93);
vec2 UVADD() { return vec2(time*0., 0.); }

float camSpeed() {return mode*.3*time;}
float pipeSpeed() {return 0.*15.*time;}
float Hash21(vec2 p)
{
    vec3 a = fract(p.xyx*vec3(123.34, 234.34, 345.65));
    a += dot(a, a+34.45);
    return fract(a.y*a.z*a.x);
}
// ---------------------------------------------------------------------------
// Hexagon Dist by BigWings
float HexDist(vec2 p) {
    p = abs(p);
    
    float c = dot(p, normalize(vec2(1.,1.73)));
    c = max(c, p.x);
    
    return c;
}
// Hash function by BigWings
vec2 N22(vec2 p)
{
    vec3 a = fract(p.xyx*vec3(123.34, 234.34, 345.65));
    a += dot(a, a+34.45);
    return fract(vec2(a.x*a.y, a.y*a.z));
}
// Hexagon Coords by BigWings
vec4 HexCoords(vec2 UV) 
{
    vec2 r = vec2(1., sqrt(3.));
    vec2 h = r*.5;
    
    vec2 a = mod(UV, r)-h;
    vec2 b = mod(UV-h, r)-h;
    
    vec2 gv = dot(a, a) < dot(b,b) ? a : b;
    
    float x = atan(gv.x, gv.y);
    float y = .5-HexDist(gv);
    vec2 id = UV - gv;
    return vec4(x, y, id.x,id.y);
}
vec3 Hive(vec2 UV, float a)
{
    vec3 col = vec3(0);
    vec4 hc = HexCoords(UV);
    float c = smoothstep(0.08, 0.11, hc.y); // inside each hexagon (without the edges)
    
    // waves based on hexagon's ID
    //float b1 = 0.5 + 0.43*sin(hc.z*5. + hc.w*3. + 4.*time);
    float b1 = 0.5 + 0.43*sin(hc.z*24. + hc.w*3.*34. + 4.*time);
    // Spirals on each hexagon
    float b2 = 0.5 + 0.5*cos(hc.x*10. + hc.y*45. + 8.*time);
    
    //vec4 ehc = HexCoords((hc.xz+0.1*vec2(0., time))*3.*vec2(2.0693,2.5) + 100. + vec2(4.,0.));
    //float hexagons = smoothstep(0.,0.01, ehc.y)*mod(ehc.z,2.)*mod(ehc.w,2.);
    //float b3 = b1*(1.-hexagons);

    float everyOtherTile = mod(floor(hc.z),2.);

    float edges = 1.-c;
    float eSquares = cos(hc.y*20. + time)*sin(hc.x*20. + time); // edges squares
    eSquares = smoothstep(0.,0.01,eSquares);
    float b4 = edges * eSquares; 

    // bottom color
    vec3 col1 = b2*c*vec3(0.4274,0.847,0.8941) // azur color for the inverse of the waves
          + 2.*b1*c*vec3(0.4078,0.1725,0.0705)  // brown color for the waves
          + 5.*vec3(b1,0,(1.-b1))*c*0.2          // add some rg colors to the waves and to the inverse of them
          + b4*2.*vec3(0.8431,0.7607,0.5019);   // brown-ish color for the edges of each hexagon
    // top color
    vec3 col2 = b2*(1.-b1)*c*vec3(0.4745,0.3705,0.9039) //  purple color for the inverse of the waves
          + b1*c*vec3(0.8431,0.7607,0.5019)  // brown color for the waves
          + vec3(b1,0,(1.-b1))*c*0.08          // add some rg colors to the waves and to the inverse of them
          + b4*1.3;   // white color for the edges of each hexagon
    
    col = mix(col1,col2, a);
    
    //vec3 test = vec3(hc.zw*0.005,0.);//everyOtherTile;
    
    return col;//vec3(edges);
}
// ---------------------------------------------------------------------------
float torusRipples(vec2 torusUVPI)
{
    return 0.5+0.5*sin(torusUVPI.x * 150. + pipeSpeed());
}
// ---------------------------------------------------------------------------
vec2 GetTorusUV(vec3 p, vec2 r, float rot, float checker)
{
    if(rot == 1.)
        p = RotZ(p, PI);
    //float checker2 = rot == 1.? 1. : 0.;
    float x = atan(p.x, p.z)/(PI*0.5);
    float y = atan(length(p.xz)-r.x, p.y)/PI*0.5 + 0.5;
    //if(rot == 1.)
    //    y = 1. - y;//0.5;
    return vec2(x,y);    
}
vec2 GetTorusUVPI(vec3 p, vec2 r, float rot, float checker)
{
    if(rot == 1.)
        p = RotZ(p, PI);
    float x = atan(p.x, p.z);
    float y = atan(length(p.xz)-r.x, p.y);
    //if(rot == 1.)
    //    y += PI;
    return vec2(x,y);    
}
// ---------------------------------------------------------------------------
float sdTorus(vec3 p, vec2 r, float rot, float checker, vec2 torusUV)
{
    //vec2 flag = torusFlag(p, r, rot, checker);
    //vec2 torusUV = GetTorusUV(p, r, rot, checker);
    //float ripples =  + 0.004*torusRipples(torusUVPI);
    float torusDist = length(vec2(length(p.xz) - r.x, p.y) ) - r.y;
    vec4 h = HexCoords(torusUV);
    float hive = 0.015*smoothstep(0.,0.1,h.y) - 0.015*smoothstep(0.1,0.2,h.y);
    
    float hiveTorus = torusDist + hive;
    float holesTorus = max(-hiveTorus,torusDist);
    return hiveTorus*0.6;
}
// ---------------------------------------------------------------------------
vec3 spherePos() {
    return vec3(0.,1.2 + 0.3*sin(time),0.);
}
// ---------------------------------------------------------------------------
float Hash31(vec3 p)
{
    vec3 a = fract(p*vec3(123.34, 234.34, 345.65));
    a += dot(a, a+34.45);
    return (a.x*a.y*a.z);
}
// ---------------------------------------------------------------------------
float sdBox2(vec3 p, vec3 s, float speed) 
{
  vec3 a = vec3(0.05*sin(p.y*p.z*3. + speed), 0.,0.);
  vec3 q = abs(p + a.xyy) - s - s*0.5*a.xyx;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
// ---------------------------------------------------------------------------
float GetWaves(vec3 p)
{
    float waves =  0.05*sin(p.z*1.76+ 2.12*p.x)*cos(p.z + p.x*3.321) 
                   + 0.1*sin(p.x*2.571 + p.z*2.512)
                   + (0.5 + 0.5*sin(p.x*1. + p.z*4.))*0.1*cos(cos(p.z*2. + p.x*4.142)*sin(p.z*1.123 + p.x*3.13))
                   + 0.1*sin(sin(0.*p.x*4. + p.z)*cos(p.x*2.22 + p.z*4.193) + p.x*2.)
                   + 0.2*sin(p.z*0.385 + p.x*0.941 + 0.2*cos(p.x*5.));
    return waves;
}

vec3 GetTorusCol(vec2 torUVPI, vec2 torUV, vec2 ID)
{
    vec3 tex = vec3(0.0);//texture(iChannel2, torUV + time*0.6).xyz;
    
    vec3 torCol;
    
    float ripples = torusRipples(torUVPI);
    torCol += vec3(1.,0.7,0.6)*ripples*tex; // low brown flow
    
    float waves = 0.5+0.5*sin(torUVPI.x*2. + 3.*time);
    waves = smoothstep(0.3, 0., waves);
    vec3 wavesCol = vec3(3.8, 0.87, 2. + 1.5*sin(time*5.)) * tex*tex;
    wavesCol *= 2.;
    torCol += waves*wavesCol; // strong flow
    
    float lines = 0.5+0.5*sin(torUVPI.y*7. + 0.*10.*time);
    lines = smoothstep(0.4, 0., lines);
    vec3 linesCol = vec3(0., 3.4, 10.66);
    float ripples2 = 0.5 + 0.5*sin(torUVPI.x*30. + 10.*time);
    linesCol = ripples2*lines*(linesCol);;
    linesCol *= 3.5 + 3.3*sin(time*7.);
    torCol += linesCol;
    
    //return waves*wavesCol;
    //return  vec3(1.,0.7,0.6)*ripples*tex;
    return torCol;
}
// ---------------------------------------------------------------------------
vec4 Truchet(vec3 p)
{
    //vec3 p_temp = p;
    vec2 ID = floor(p.xz);
    float hash = Hash21(ID);
    float checker = mod(ID.x + ID.y, 2.)*2. -1.;
    vec2 torusRad = vec2(0.5, 0.15);
    float rot = -1.;
    if(hash < 0.5)
    {
        p = RotZ(p, PI);
        rot = 1.;
    }
    vec3 truchetBoxPos = p - vec3(0.5, 0., 0.5);
    truchetBoxPos.x = fract(truchetBoxPos.x + 0.5) - 0.5;
    truchetBoxPos.z = fract(truchetBoxPos.z + 0.5) - 0.5;
    
    
    vec3 torus1Pos = truchetBoxPos - vec3(0.5, 0., 0.5);
    //float torusUVScale = 1.;
    vec2 torus1UV = GetTorusUV(torus1Pos, torusRad, rot, checker);
    torus1UV *= checker * rot * UVMUL;
    torus1UV += UVADD();
    
    vec2 torus1UVPI = GetTorusUVPI(torus1Pos, torusRad, rot, checker);
    torus1UVPI *= checker * rot * UVPIMUL;
    torus1UVPI += UVPIADD;
    vec3 hive1 = Hive(torus1UV, 0.);
    vec3 torus1Col = hive1;//GetTorusCol(torus1UVPI, torus1UV, ID);
    //torus1Col.x = torus1UV.x;
    //torus1Col = texture(iChannel0, torus1UV + time*0.1).xyz;
    //torus1Col = vec3(smoothstep(0.,0.1,sin(torus1UVPI.x + time*4.)*cos(torus1UVPI.y + time*4.)));
    vec4 torus1Dist = vec4(torus1Col, sdTorus(torus1Pos, torusRad, rot, checker, torus1UV));
    
    vec3 torus2Pos = truchetBoxPos + vec3(0.5, 0., 0.5);
    vec2 torus2UV = GetTorusUV(torus2Pos, torusRad, rot, checker);
    torus2UV *= checker * rot * UVMUL;
    torus2UV += UVADD();
    
    vec2 torus2UVPI = GetTorusUVPI(torus2Pos, torusRad, rot, checker);
    torus2UVPI *= checker * rot * UVPIMUL;
    torus2UVPI += UVPIADD;
    vec3 hive2 = Hive(torus2UV, 0.);
    vec3 torus2Col = hive2;//GetTorusCol(torus2UVPI, torus2UV, ID);
    //torus2Col.x = torus2UV.x;
    //torus2Col = texture(iChannel0, torus2UV + time*0.1).xyz;
    //torus2Col = vec3(smoothstep(0.,0.1,sin(torus2UVPI.x + time*4.)*cos(torus2UVPI.y + time*4.)));
    vec4 torus2Dist = vec4(torus2Col, sdTorus(torus2Pos, torusRad, rot, checker, torus2UV));
    
    vec4 torusDist = min2(torus1Dist, torus2Dist);

    return torusDist;
}
// ---------------------------------------------------------------------------
vec4 GetDist(vec3 p) // return vec4(Object color, min Distance)
{    
    p = RotZ(p, sin(p.x*0.025 + PI));
    vec3 p2 = p;
    if(p.y < 0.)
    p.y = fract(p.y-0.5)-0.5;
    float ID = floor(p2.y-0.5);
    float h = fract(sin(ID*241.42)*cos(ID*841.24));
    if(h < 0.5)
        p.xz += ID*123.;
    
    vec4 res = Truchet(p - vec3(0., 0., 0.));
    //res.w = -max(p2.y - 1., -res.w);
    
    return res;
}
// ---------------------------------------------------------------------------
vec3 GetNormal(vec3 p)
{
    float d = GetDist(p).w;
    vec2 e = vec2(.01, 0.);
 
    vec3 n = d-vec3(GetDist(p-e.xyy).w, 
                        GetDist(p-e.yxy).w, 
                        GetDist(p-e.yyx).w);
    return normalize(n);
}
// ---------------------------------------------------------------------------
// fog by iq
vec3 applyFog( vec3  rgb, float distance, float strength, vec3 fogColor)
{
    float fogAmount = 1.0 - exp( -distance*strength );
    return mix( rgb, fogColor, fogAmount );
}
// ---------------------------------------------------------------------------
vec3 applyFog( in vec3  rgb,      // original color of the pixel
               in float distance, // camera to point distance
               in vec3  rayDir,   // camera to point vector
               in vec3  sunDir,   // sun light direction
               in float strength,
               in vec2 mou)  
{
    float fogAmount = 1.0 - exp( -distance*strength );
    float sunAmount = max( dot( rayDir, sunDir ), 0.0 );
    vec3  fogColor  = mix( mix(vec3(0.1,0.0,0.3), vec3(0.7,0.4,1.), sunDir.y),
                           vec3(1.2,1.,0.5),
                           pow(sunAmount,10.) );
    fogColor = mix(fogColor, vec3(0.3,0.5,1.), rayDir.y + 0.2);
    fogColor += -rayDir.y*vec3(1.5,1.3,0.3);
    fogColor -= vec3(1.)*clamp(abs(rayDir.x), 0., 1.);
    fogColor += 0.25*(1. - vec3(1.)*clamp(abs((rayDir.y*15. * rayDir.x))*1.5, 0., 1.)) * smoothstep(-0.5, 0.05, rayDir.y);
    rayDir = RotZ(rayDir, 0.5*PI);
    rayDir = abs(rayDir);
    //fogColor = max(vec3(-0.2), fogColor);
    fogColor += 0.25*(1. - vec3(1.)*clamp(abs((rayDir.y*15. * rayDir.x))*1.5, 0., 1.)) * smoothstep(-0.05, 0.05, rayDir.y);
    
    return mix( rgb, fogColor, fogAmount );
}
// ---------------------------------------------------------------------------
vec4 RayMarch(vec3 ro, vec3 rd, int steps) 
{
    vec3 result= vec3(1.,1.,0.)*0.;
    vec4 dS;
    float dO;;
    vec3 p;  
    for(int i = 0; i<steps; i++)
    {
        p = ro + rd * dO;
        if(dO > MaxDist) {
            result = vec3(0.);
            break;
        }
        dS = GetDist(p);
        if(abs(dS.w) < 0.0001) {
            result = dS.xyz;
            break; 
        }
        dO += dS.w;
    }     
    return vec4(result.xyz,dO);
}
// ---------------------------------------------------------------------------
float softShadow( in vec3 ro, in vec3 rd, float mint, float maxt, float w )
{
    float s = 1.0;
    float t = mint;
    for( float i=0.; i<maxt; i++ )
    {
        float h = GetDist(ro + rd*t).w;
        s = min( s, 0.5+0.5*h/(w*t) );
        if( s<0.0 ) break;
        t += h;
    }
    s = max(s,0.0);
    return s*s*(3.0-2.0*s); // smoothstep
}
// ---------------------------------------------------------------------------
float GetLight(vec3 p, vec3 lightPos, float lightPower, float shadowStrength, int steps)
{
    vec3 l = normalize(lightPos - 0.*p);
    vec3 n = GetNormal(p);
    float dif = clamp(dot(n, l*lightPower), 0., 1.);
    //float d = RayMarch(p + n*0.001, l, steps).w;
    //if(d < length(lightPos-p*0.)) {dif *= shadowStrength;}
    float sunShadow = softShadow(p + n*0.001, lightPos, 0., 100., 0.1);
    return clamp(0.5 + 0.5*dif, 0., 1.)*clamp((0.2 + 0.8*sunShadow), 0., 1.);
}
// ---------------------------------------------------------------------------
float specularReflection(vec3 p, vec3 rd, vec3 lightPos, float intensity, float shininessVal)
{
    vec3 N = GetNormal(p);
    vec3 L = normalize(lightPos - 0.*p);
    float lambertian = max(dot(L, N), 0.0);
    float specular = 0.;
      if(lambertian > 0.0) {
        vec3 R = reflect(-L, N);      // Reflected light vector
        vec3 V = normalize(-rd); // Vector to viewer
        // Compute the specular term
        float specAngle = max(dot(R, V), 0.0);
        specular = pow(specAngle, shininessVal);
      }
    return specular * intensity;
}
// ---------------------------------------------------------------------------
// calcOcclusion by iq
float calcOcclusion(vec3 p)
{
    vec3 n = GetNormal(p);
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.01 + 0.11*float(i)/4.0;
        vec3 opos = p + h*n;
        float d = GetDist(opos).w;
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 2.0*occ, 0.0, 1.0 );
}
// ---------------------------------------------------------------------------
float sminP( float a, float b, float s ){

    float h = clamp( 0.5+0.5*(b-a)/s, 0.0, 1.0 );
    return mix( b, a, h ) - s*h*(1.0-h);
}
void cam(vec2 mou, inout vec3 ro, inout vec3 lookat)
{
    ro = vec3(0.7, 1., 0.7);
    if(time < 10.)
        ro.y = 7. + 6.*sin(time/20.*PI + PI);
    ro.z -= time*2.;
    lookat = ro + vec3(0.5*sin(time*0.2287),  -0.2 + 0.4*sin(time*0.3752), -1.);

}
// ---------------------------------------------------------------------------
void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;

    
    vec3 col = vec3(0.,0.,0.);
 
    

    float zoom = 1.;
    
    vec2 mou = 5.*(mouse*resolution.xy.xy-.5*resolution.xy)/resolution.y;

    vec3 ro;
    vec3 lookat;
    cam(mou, ro, lookat);
    
    //lookat = ro + vec3(0.5*sin(time*0.2287),  -0.2 + 0.4*sin(time*0.3752), -1.);
    
    if(mode == 0.) {
    ro = vec3(0.01, 3., -1.);
    ro.xz *= Rot(mou.x);
    ro.y += mou.y*5.;
    lookat = vec3(0.01, 0., -1.1);
    }

    vec3 F = normalize(lookat-ro); // Forward
    vec3 R = normalize(cross(vec3(0., 1., 0.), F)); //Right
    vec3 U = cross(F, R); //Up

    vec3 C = ro + F*zoom;
    vec3 I = C + uv.x*R + uv.y*U;
    vec3 rd = normalize(I-ro);

    vec4 d = RayMarch(ro,rd, MaxSteps); 
    vec3 p = ro + rd*d.w;
    
    //vec3 lightPos = normalize(vec3(0.,max(0.2,1. - 0.02*time) + 0.*mou.y,-1.));// + ro;//vec3(1.) + ro;//ro + 0.1*normalize(lookat);
    vec3 lightPos = vec3(0.,0.3,-1.);
    //if(mode == 0.)
    //    lightPos = ro;
    
    float dif = GetLight(p, lightPos, 1., 0.5, MaxSteps);
    vec3 n = GetNormal(p);
    //float sunShadow = softShadow(p + n*0.001, lightPos, 0., 100., 0.1);
    float occ = calcOcclusion(p);
    float spRefSun = specularReflection(p, rd, lightPos, 1., 7.);
    float spRefSky = specularReflection(p, rd, vec3(0., 5., 0.), 1., 5.);
    float skyDif = clamp(dot(vec3(0.,1.,0), GetNormal(p)), 0., 1.);
    float groundDif = clamp(dot(vec3(0.,-1.,0.), GetNormal(p)), 0., 1.);
    
    col = d.xyz * dif * occ
          + spRefSun * vec3(1.,1., 0.9)
          + skyDif * vec3(0.1, 0.2, 0.5)
          + spRefSky*vec3(0.1,0.2,1.)
          + groundDif * vec3(0.5,0.4,0.1);

    //col = applyFog(col, d.w, 0.15, vec3(0.6,0.5,0.4));
    
    rd = RotZ(rd, sin(rd.x + PI));
    col = applyFog(col, d.w, rd, normalize(lightPos), 0.21, mou);
    //col = pow3(col,1.3);
    //col = vec3(groundDif);
   //col = skyDif * vec3(0.1, 0.2, 0.5);
    glFragColor = vec4(col,0.1);
}
