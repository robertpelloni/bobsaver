#version 420

// original https://www.shadertoy.com/view/fsjcWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// psrdnoise (c) Stefan Gustavson and Ian McEwan,
// ver. 2021-12-02, published under the MIT license:
// https://github.com/stegu/psrdnoise/
float psrdnoise(vec2 x, vec2 period, float alpha, out vec2 gradient)
{
    vec2 uv = vec2(x.x+x.y*0.5, x.y);
    vec2 i0 = floor(uv), f0 = fract(uv);
    float cmp = step(f0.y, f0.x);
    vec2 o1 = vec2(cmp, 1.0-cmp);
    vec2 i1 = i0 + o1, i2 = i0 + 1.0;
    vec2 v0 = vec2(i0.x - i0.y*0.5, i0.y);
    vec2 v1 = vec2(v0.x + o1.x - o1.y*0.5, v0.y + o1.y);
    vec2 v2 = vec2(v0.x + 0.5, v0.y + 1.0);
    vec2 x0 = x - v0, x1 = x - v1, x2 = x - v2;
    vec3 iu, iv, xw, yw;
    if(any(greaterThan(period, vec2(0.0)))) {
        xw = vec3(v0.x, v1.x, v2.x);
        yw = vec3(v0.y, v1.y, v2.y);
        if(period.x > 0.0)
            xw = mod(vec3(v0.x, v1.x, v2.x), period.x);
        if(period.y > 0.0)
            yw = mod(vec3(v0.y, v1.y, v2.y), period.y);
        iu = floor(xw + 0.5*yw + 0.5); iv = floor(yw + 0.5);
    } else {
        iu = vec3(i0.x, i1.x, i2.x); iv = vec3(i0.y, i1.y, i2.y);
    }
    vec3 hash = mod(iu, 289.0);
    hash = mod((hash*51.0 + 2.0)*hash + iv, 289.0);
    hash = mod((hash*34.0 + 10.0)*hash, 289.0);
    vec3 psi = hash*0.07482 + alpha;
    vec3 gx = cos(psi); vec3 gy = sin(psi);
    vec2 g0 = vec2(gx.x, gy.x);
    vec2 g1 = vec2(gx.y, gy.y);
    vec2 g2 = vec2(gx.z, gy.z);
    vec3 w = 0.8 - vec3(dot(x0, x0), dot(x1, x1), dot(x2, x2));
    w = max(w, 0.0); vec3 w2 = w*w; vec3 w4 = w2*w2;
    vec3 gdotx = vec3(dot(g0, x0), dot(g1, x1), dot(g2, x2));
    float n = dot(w4, gdotx);
    vec3 w3 = w2*w; vec3 dw = -8.0*w3*gdotx;
    vec2 dn0 = w4.x*g0 + dw.x*x0;
    vec2 dn1 = w4.y*g1 + dw.y*x1;
    vec2 dn2 = w4.z*g2 + dw.z*x2;
    gradient = 10.9*(dn0 + dn1 + dn2);
    return 10.9*n;
}

// Return the three nearest points in a hexagonal grid
// (the simplex neighbors)
void hexgrid(vec2 v,
    out vec2 p0, out vec2 i0,
    out vec2 p1, out vec2 i1,
    out vec2 p2, out vec2 i2) {
    
    const float stretch = 1.0/0.8660; // No use for tiling here,
    const float squash = 0.8660;  // use isotropic simplex grid
    
  //  v.y = v.y + 0.0001; // needed w/ stretched grid (rounding errors)
  v.y = v.y * stretch;
  // Transform to grid space (axis-aligned, modified "simplex" grid)
  vec2 uv = vec2(v.x + v.y*0.5, v.y);
  // Determine which simplex we're in, with i0 being the "base"
  i0 = floor(uv);
  vec2 f0 = fract(uv);
  // o1 is the offset in simplex space to the second corner
  float cmp = step(f0.y, f0.x);
  vec2 o1 = vec2(cmp, 1.0-cmp);
  // Enumerate the remaining simplex corners
  i1 = i0 + o1;
  i2 = i0 + vec2(1.0, 1.0);
  // Transform corners back to texture space
  p0 = vec2(i0.x - i0.y * 0.5, i0.y);
  p1 = vec2(p0.x + o1.x - o1.y * 0.5, p0.y + o1.y);
  p2 = vec2(p0.x + 0.5, p0.y + 1.0);
  p0.y = p0.y * squash;
  p1.y = p1.y * squash;
  p2.y = p2.y * squash;
}

// Compute the value of a "Gabor-ish wavelet" from point p
// in direction g, evaluated at point x with phase shift alpha
float wavelet(vec2 x, vec2 p, vec2 g, float alpha) {
    vec2 d = x - p;
    float w = 0.8 - dot(d,d);
    w = max(w, 0.0);
    float w2 = w * w;
    return w2 * sin(mod(dot(d,g)+alpha,1.0)*2.0*6.2832);
}

// Permutation functions for the hash values
vec3 perm1(vec3 i) {
  vec3 im = mod(i, 289.0);
  return mod(((im*34.0)+10.0)*im, 289.0);
}

vec3 perm2(vec3 i) {
    vec3 im = mod(i, 361.0);
    return mod((im*38.0+8.0)*im, 361.0);
}

vec3 hashphase(vec3 iu, vec3 iv) {
    return perm1(perm2(iu)+iv)*(1.0/289.0);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/(resolution.x+resolution.y)*2.0;

    vec2 p0, p1, p2;
    vec2 i0, i1, i2;

    vec2 p = uv*32.0-16.0;
    hexgrid(p, p0, i0, p1, i1, p2, i2);

    // A vector field to visualise: the gradient of 2-D psrdnoise
    vec2 g;
    vec2 d = vec2(0.0*time, 0.0);
    float n = 0.5+0.5*psrdnoise(p*0.05+d, vec2(0.0), 0.2*time, g);

//    g = vec2(-g.y,g.x);

    float A = length(g); // Scale wavelet amplitudes with norm of g
    A = max(0.0, A-0.3); // Tweak for display (stomp out low values)
    g = normalize(g);    // If left unnormalized: changes the wavelength
    // pseudo-random phase works best
    vec3 ph = hashphase(vec3(i0.x,i1.x,i2.x), vec3(i0.y,i1.y,i2.y));
    
    float alpha = 1.0*time;

    float w0 = wavelet(p, p0, g, ph.x + alpha);
    float w1 = wavelet(p, p1, g, ph.y + alpha);
    float w2 = wavelet(p, p2, g, ph.z + alpha);
    
    float f = 0.3*A*(w0 + w1 + w2) + 0.1;

    vec3 bg = vec3(0.0,n*0.5,n);
    vec3 fg = vec3(1.0,1.0,1.0);

    vec3 mixcolor = mix(bg,fg,f);

    glFragColor = vec4(mixcolor, 1.0);
}
