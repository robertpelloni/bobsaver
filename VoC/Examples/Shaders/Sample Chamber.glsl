#version 420

// original https://www.shadertoy.com/view/MttBRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

struct Shape{
  float dist;
  vec4 color;
};
    
//=======================
// Utility Functions
//=======================
float random(vec2 v) {
  return fract(sin(dot(v*0.1, vec2(324.654, 156.546)))*46556.2);
}

mat2 rot(float a){
  float r = cos(a);
  float f = sin(a);
  return mat2(r, f, -f, r);
}

float fCone(vec3 p, float radius, float height) {
    vec2 q = vec2(length(p.xz), p.y);
    vec2 tip = q - vec2(0, height);
    vec2 mantleDir = normalize(vec2(height, radius));
    float mantle = dot(tip, mantleDir);
    float d = max(mantle, -q.y);
    float projected = dot(tip, vec2(mantleDir.y, -mantleDir.x));
    
    // distance to tip
    if ((q.y > height) && (projected < 0.)) {
        d = max(d, length(tip));
    }
    
    // distance to base ring
    if ((q.x > radius) && (projected > length(vec2(height, radius)))) {
        d = max(d, length(q - vec2(radius, 0)));
    }
    return d;
}

float sdHexPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
    return max(q.z-h.y,max((q.x*0.866025+q.y*0.5),q.y)-h.x);
}

float vmax(vec3 v) {
    return max(max(v.x, v.y), v.z);
}

// Box: correct distance to corners
float fBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}

float mixColors(float r, float v, float z){
  return clamp(0.5+0.5*(v-r)/z, 0., 1.);
}

float mixShapes(float v, float f, float r){
  float z = mixColors(v, f, r);
  return mix(f,v,z)-r*z*(1.-z);
}

float opS( float d1, float d2 )
{
    return max(-d1,d2);
}

float pModPolar(inout vec2 v, float r){
  float f = 6.28318/r;
  float z = atan(v.y, v.x)+f*0.5;
  float m = floor(z/f);
  z = mod(z, f)-f*0.5;
  v = vec2(cos(z), sin(z))*length(v);
  return m;
}

void pR45(inout vec2 p) {
    p = (p + vec2(p.y, -p.x))*sqrt(0.5);
}

float pMod1(inout float p, float size) {
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    p = mod(p + halfsize, size) - halfsize;
    return c;
}

float fOpUnionColumns(float a, float b, float r, float n) {
    if ((a < r) && (b < r)) {
        vec2 p = vec2(a, b);
        float columnradius = r*sqrt(2.)/((n-1.)*2.+sqrt(2.));
        pR45(p);
        p.x -= sqrt(2.)/2.*r;
        p.x += columnradius*sqrt(2.);
        if (mod(n,2.) == 1.) {
            p.y += columnradius;
        }
        // At this point, we have turned 45 degrees and moved at a point on the
        // diagonal that we want to place the columns on.
        // Now, repeat the domain along this direction and place a circle.
        pMod1(p.y, columnradius*2.);
        float result = length(p) - columnradius;
        result = min(result, p.x);
        result = min(result, a);
        return min(result, b);
    } else {
        return min(a, b);
    }
}

float fOpEngrave(float a, float b, float r) {
    return max(a, (a + r - abs(b))*sqrt(0.5));
}

float fOpUnionStairs(float a, float b, float r, float n) {
    float s = r/n;
    float u = b-r;
    return min(min(a,b), 0.5 * (u + a + abs ((mod (u - a + s, 2.* s)) - s)));
}

//=======================

Shape environment(vec3 c){
  Shape shape;
  shape.dist = 1000.; // Draw Distance
  shape.color = vec4(1.); // Initial Color
    
  // Coordinate Systems
  vec3 g = c; // Ground
  vec3 p = c; // PlaceHolder
  vec3 a = c; // Ground Texture
  vec3 pill = c; // Pillars
  vec3 s = c; // Side
  vec3 pol = c; // Pole 
  vec3 l = c; // Lantern
  vec3 h = c; // Hole in Lantern
    
  // Ground
  vec4 gColor = vec4(0.9, 0.1, 0.1, 0.0); 
  g.xy *= rot(radians(90.)); 
  g.x = abs(g.x) - 4.; 
  float ground = fBox(g+vec3(2.,0.5,2.), vec3(0.25, 3.25, 2000000.75));
  
  // PlaceHolder
  vec4 placeColor = vec4(0.,0.,0.,0.); 
  p.xy *= rot(radians(90.)); 
  float placeHolder = fBox(p+vec3(2.,2. ,4.), vec3(3., 0., 3.)); 
    
  // Ground Texture
  vec4 gtColor = vec4(1.,1.,1.,1.); 
  a.xy *= rot(radians(90.)); 
  a.zy *= rot(radians(90.)); 
  a.z = abs(g.x) - 4. ;
  pMod1(a.y, 1.);
  // pMod1(a.x, 1.);
  float groundTexture = sdHexPrism(a+vec3(1.6,0.9,2.1), vec2(0.7, 0.4)); 
    
  // Pillars
  vec4 pColor = vec4(0.6, 0.8, 0.8, 0.); 
  pill.z = abs(pill.z) + 5.; 
  pill.x = abs(pill.x) - 1.; 
  pMod1(pill.z, 8.);
  pill.xy *= rot(radians(90.));
  float pillar = fBox(pill+vec3(0.,3.,1.5), vec3(2., 0.5, 0.)); 
  pillar = fOpUnionStairs(ground, pillar, 1.3, 4.);
    
  // Side 
  //vec4 sColor = vec4(0.5, 0.6, 0.3, 0.0); 
  s.x = abs(s.x) - 6.; 
  pMod1(s.z, 5.); 
  float side = fBox(s+vec3(3.,1., -5.), vec3(0.2, .5, 7.)); 
  side = fOpUnionColumns(ground, side, 1.3, 4.); 
    
  // Lantern Pole
  vec4 poleColor = vec4(1.,1.,1., 1.); 
  pMod1(pol.z, 7.5); 
  float pole = fBox(pol+vec3(0.,-1.5, -1.), vec3(0.1, 0.4, 0.1)); 
   
  // Lantern
  vec4 lColor = vec4(1., 1., 0., 0.); 
  pMod1(l.z, 7.5);
  float lantern = fBox(l+vec3(0., -1., -1.), vec3(0.3, 0.3, 0.3)); 
    
  // Hole in Lantern
  pMod1(h.z, 7.5); 
  float hole = fBox(h+vec3(0., -1., -0.85), vec3(0.1, 0.1, 0.1)); 
   
  
  lantern = fOpEngrave(lantern, hole, 0.1);    
    
  shape.dist = max(ground, -placeHolder);  
  shape.dist = min(shape.dist, groundTexture); 
  shape.dist = min(shape.dist, pillar); 
  shape.dist = min(shape.dist, side); 
  shape.dist = min(shape.dist, pole); 
  shape.dist = min(shape.dist, lantern); 
  shape.dist = min(shape.dist, hole); 
    
  shape.color = mix(gColor, placeColor, mixColors(placeHolder, ground, 1.0));  
  shape.color = mix(shape.color, gtColor, mixColors(groundTexture, shape.dist, 0.1));
  shape.color = mix(shape.color, pColor, mixColors(pillar, shape.dist, 1.0));
  shape.color = mix(shape.color, lColor, mixColors(lantern, shape.dist, 1.0)); 
  shape.color = mix(shape.color, poleColor, mixColors(pole, shape.dist, 1.0)); 
  //shape.color = mix(shape.color, sColor, mixColors(side, shape.dist, 0.3)); 
  
  return shape; 
}

Shape map(vec3 c){
  Shape enviro = environment(c);
  return enviro;
}

void main(void) {
  vec2 v = (gl_FragCoord.xy-0.5 * resolution.xy) / resolution.y;
 
  vec3 cam = vec3(0., 0., time*3.);
  cam.xy *= rot(radians(90.));
  vec3 f = normalize(vec3(v, 1.));
  vec3 scene = cam;
  //  scene.yx *= rot(time);
  glFragColor = vec4(0.);

  // Ray Marcher
  for(float z = 0.1 ; z <= 1.; z += 0.03){
    Shape c = map(scene); // Calc SDF
    if(c.dist < 0.0001){
      glFragColor = c.color*(1.-z); // Hit  - invert pixels
      break;
    }
    scene += f * c.dist;
  }
}
