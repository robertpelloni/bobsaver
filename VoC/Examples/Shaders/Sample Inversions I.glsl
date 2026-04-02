#version 420

// original https://www.shadertoy.com/view/4lfBzj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

struct Ray {
  vec3 q;               // origin
  vec3 d;               // direction
};

struct Hit {
  float t;      // solution to p=q+t*d
  vec3 n;       // normal
  vec3 color;
};

struct Sphere {
  float r;      // radius
  vec3 p;       // centre
  vec3 color;
};

bool invert = true;

Sphere invertSphere(Sphere s) {
  // Use mouse position to determine centre of inversion (for x and y)
  vec3 icentre = vec3(0.5,-0.1,-1.25);
  // On startup mouse*resolution.xy.x = mouse*resolution.xy.y = 0
  //if (mouse.xy*resolution.xy > 0.0) {
  //    icentre = vec3(3.0*(mouse*resolution.xy.x-0.5*resolution.x)/resolution.x,
  //                    3.0*(mouse*resolution.xy.y-0.5*resolution.y)/resolution.y,
  //                    -1.25);
  //  }
  // Shift origin to sphere centre
  vec3 p = s.p - icentre;
  float r = s.r;
  float c = length(p);
  // This inverts the sphere (in the origin).
  float k = 1.0/((c+r)*(c-r));
  // Shift back
  return Sphere(r*k, p*k+icentre, s.color);
}

bool intersectSphere(Sphere s, Ray ray, out Hit hit) {
  vec3 p = s.p;
  float r = s.r;
  float c = length(p);
  vec3 q = ray.q, d = ray.d;
  // |q + t*d - p|^2 = r^2
  float B = dot(q-p,d);
  float C = dot(q,q)-2.0*dot(q,p)+(c+r)*(c-r);
  float D = B*B - C;
  if (D < 0.0) return false;
  D = sqrt(D);
  float t,t1;
  if (B >= 0.0) {
    t = -B-D; t1 = C/t;
  } else {
    t1 = -B+D; t = C/t1;
  }
  if (t < 0.0) t = t1;
  if (t < 0.0) return false;
  // Normal is the radial vector of sphere
  hit = Hit(t, (q+t*d-p)/r, s.color);
  return true;
}

vec3 vertices[12];
int colors[12];
void setVertices() {
  float phi = 0.80902;
  // Three golden rectangle, oriented to
  // the three axes. 
  vertices[0] = vec3( 0.5, phi,0); //++0 A
  vertices[1] = vec3( 0.5,-phi,0); //+-0 B
  vertices[2] = vec3(-0.5, phi,0); //-+0 C
  vertices[3] = vec3(-0.5,-phi,0); //--0 D

  vertices[4] = vec3(0, 0.5, phi); //0++ B
  vertices[5] = vec3(0, 0.5,-phi); //0+- D
  vertices[6] = vec3(0,-0.5, phi); //0-+ C
  vertices[7] = vec3(0,-0.5,-phi); //0-- A

  vertices[8]  = vec3( phi,0, 0.5); //+0+ D
  vertices[9]  = vec3( phi,0,-0.5); //+0- C
  vertices[10] = vec3(-phi,0, 0.5); //-0+ A
  vertices[11] = vec3(-phi,0,-0.5); //-0- B

  // A nice 4-coloring of icosahedron vertices
  colors[0] = colors[7] = colors[10] = 0;
  colors[1] = colors[4] = colors[11] = 1;
  colors[2] = colors[6] = colors[9] = 2;
  colors[3] = colors[5] = colors[8] = 3;
}

vec3 getColor(int i) {
  if (i == 0) return vec3(1,0,0);
  if (i == 1) return vec3(1,1,0);
  if (i == 2) return vec3(0,1,0);
  if (i == 3) return vec3(0,0,1);
  return vec3(1,1,1);
}

bool intersectScene(Ray r, out Hit hit) {
  float t = 0.5*time;
  mat3 m = mat3(cos(t),0,sin(t),
                0,1,0,
                -sin(t),0,cos(t));
  setVertices();
  bool found = false;
  for (int i = 0; i < 12; i++) {
    Sphere s = Sphere(0.5, m*vertices[i], getColor(colors[i]));
    Hit hits;
    if (invert) s = invertSphere(s);
    if (intersectSphere(s,r,hits) && (!found || hits.t < hit.t)) {
      hit = hits;
      found = true;
    }
  }
  return found;
}

vec3 light;
float ambient;
float diffuse;

vec4 solve(Ray r) {
  Hit hit;
  if (!intersectScene(r,hit)) {
    return vec4(0,0,0,1);
  } else {
    vec3 n = hit.n;
    if (dot(r.d,n) > 0.0) n *= -1.0;
    vec3 baseColor = hit.color;
    vec3 color = baseColor.xyz*(ambient+diffuse*max(0.0,dot(light,n)));
    float specular = pow(max(0.0,dot(reflect(light,n),r.d)),5.0);
    color += 0.5*specular*vec3(1.0,1.0,1.0);
    color *= clamp(1.0 - (hit.t-3.0)/5.0,0.0,1.0);
    return vec4(sqrt(color),1.0);
  }
}

void mainVR( out vec4 glFragColor, in vec2 gl_FragCoord,
             in vec3 fragRayOrigin, in vec3 fragRayDir) {
  glFragColor = solve(Ray(fragRayOrigin,fragRayDir));
}

void main(void) {
  light = normalize(vec3(0.5,1.0,-1.0));
  ambient = 0.5;
  diffuse = 1.0-ambient;
  vec2 uv = 2.0*gl_FragCoord.xy/resolution.xy - 1.0;
  vec3 p = vec3(0,0,-6.0);
  // "screen" coordinate
  vec3 s = vec3(resolution.x/resolution.y * uv.x, uv.y, 0);
  vec3 d = normalize(s-p); // Direction from camera to screen point
  mainVR(glFragColor,gl_FragCoord.xy,p,d);
}
