#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tsVBDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//////////////////////////////////////////////////////////////////////
//
// "rainbow noodle orbs" by mattz
// License https://creativecommons.org/licenses/by/4.0/
//
// What it does: woven Truchet tilings of spherical polyhedra.
//
// Why: Looks neat
//
// This one was fun to write! Lots of technical challenges along the 
// way, but especially figuring out how to address all of the 
// polygon vertices of a particular polygon face, and also figuring
// out how to do G1 continuous splines on the surface of a sphere
// with analytic distance functions.
//
//////////////////////////////////////////////////////////////////////

const float PI = 3.141592653589793;
const float TOL = 1e-5;

#define MAX_POLYGON 10

//////////////////////////////////////////////////////////////////////
// from https://www.shadertoy.com/view/XlGcRh 
// original by Dave Hoskins

vec3 hashwithoutsine31(float p) {
   vec3 p3 = fract(vec3(p,p,p) * vec3(.1031, .1030, .0973));
   p3 += dot(p3, p3.yzx+33.33);
   return fract((p3.xxy+p3.yzz)*p3.zyx);
}

vec3 hashwithoutsine33(vec3 p3) {
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

float hashwithoutsine11(float p) {
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

//////////////////////////////////////////////////////////////////////
// some more hash and RNG functions

// get random color from a sphere vec
vec3 random_color_from_sphere(vec3 x) {
    return hashwithoutsine33(floor(25.*x + 0.5));    
}

// fisher-yates shuffle of array
void shuffle(inout int idx[2*MAX_POLYGON], in int cnt, in float seed) {
    
    int i = cnt - 1;
 
    for (int iter=0; iter<2*MAX_POLYGON; ++iter) {
        if (i < 1) { break; }
        int j = int(floor(hashwithoutsine11(seed) * float(i+1)));
        if (j < 0 || j > i) {
            for (int k=0; k<2*MAX_POLYGON; ++k) {
                idx[k] = k % 2;
            }
            return;
        }
        int tmp = idx[i];
        idx[i] = idx[j];
        idx[j] = tmp;
        i -= 1;
        seed += 1.0;
    }

}

//////////////////////////////////////////////////////////////////////
// if point p lies opposite m, mirror it. return the transform that
// accomplishes this.

mat3 mirror(inout vec3 p, in vec3 m) {
    
    float d = dot(p, m);
    mat3 rval = mat3(1.) - (2. * step(d, 0.)) * outerProduct(m, m);
        
    p = (rval * p);
        
    return rval;
    
}

//////////////////////////////////////////////////////////////////////
// modify the vector m to halve the angle with respect to the y
// axis (assume that m.z == 0)

vec3 half_angle(in vec3 m) {
    return normalize(vec3(m.x - 1.0, m.y, 0.0));
}

//////////////////////////////////////////////////////////////////////
// rotate about arbitrary axis/angle

mat3 rotate(in vec3 k, in float t) {
    
    if (abs(t) < TOL) {
        return mat3(1.);
    }
    
    mat3 K = mat3(0, k.z, -k.y,
                  -k.z, 0, k.x,
                  k.y, -k.x, 0);
                  
    return mat3(1.) + (mat3(sin(t)) + (1. - cos(t))*K)*K;

}

//////////////////////////////////////////////////////////////////////
// wythoff construction - mammoth function using code stolen
// from https://www.shadertoy.com/view/Md3yRB

void construct(in vec3 pqr, in int spoint, in vec3 pos,
               out mat3 tri_verts, 
               out mat3 tri_edges, 
               out vec3 poly_vertex, 
               out mat3 poly_edges, 
               out int Q_vidx, 
               out int Q_vidx2, 
               out int Q_eidx, 
               out mat3 M, 
               out float pdist_poly_edge) { 

    //////////////////////////////////////////////////////////////////////
    // part 1: construct the Schwartz triangle 

    mat4x3 spoints;
    bvec3 is_face_normal;

    float p = pqr.x;
    float q = pqr.y;
    float r = pqr.z;

    float tp = PI / p;
    float tq = PI / q;
    float tr = PI / r;

    float cp = cos(tp), sp = sin(tp);
    float cq = cos(tq);
    float cr = cos(tr);

    vec3 lr = vec3(1, 0, 0);
    vec3 lq = vec3(-cp, sp, 0);
    vec3 lp = vec3(-cq, -(cr + cp*cq)/sp, 0);
    
    lp.z = sqrt(1.0 - dot(lp.xy, lp.xy));
    
    tri_edges = mat3(lp, lq, lr);
    
    vec3 vP = normalize(cross(lr, lq));
    vec3 vR = normalize(cross(lq, lp));
    vec3 vQ = normalize(cross(lp, lr));
    
    tri_verts = mat3(vP, vQ, vR);

    if (spoint < 3) {
        poly_vertex = tri_verts[spoint];
    } else if (spoint == 3) {
        poly_vertex = normalize(cross(lq - lr, lp));
    } else if (spoint == 4) {
        poly_vertex = normalize(cross(lr - lp, lq));
    } else if (spoint == 5) {
        poly_vertex = normalize(cross(lp - lq, lr));
    } else {
        poly_vertex = normalize(cross(lp-lq, lr-lp));
    }
    
    is_face_normal = bvec3(true);
    
    for (int i=0; i<3; ++i) {
        poly_edges[i] = normalize(cross(poly_vertex, tri_edges[i]));
        for (int j=0; j<2; ++j) {
            int vidx = (i+j+1)%3;
            if (abs(dot(tri_verts[vidx], poly_edges[i])) < TOL) {
                is_face_normal[vidx] = false;
            }
        }
    }

    //////////////////////////////////////////////////////////////////////
    // part 2: use space folding to make sure pos lies in the triangular 
    // cone whose edge planes are given by tri_edges
    //
    // this part of the function was largely determined by trial and
    // error. possibly if I understood more about symmetry I would be
    // able to get it a little simpler

    
    ////////////////////////////////////////////////////
    // part 2a: guarantee that the point lives inside
    // the cluster of p triangles that share the vertex
    // (0, 0, 1)
    
    M = mirror(pos, vec3(1, 0, 0));
    
    vec3 m = tri_edges[0];

    for (float i=0.; i<5.; ++i) {

        // mirror
        M *= mirror(pos, m);
        m -= tri_edges[1] * 2.0 * dot(m, tri_edges[1]);

        M *= mirror(pos, m);
        m -= tri_edges[2] * 2.0 * dot(m, tri_edges[2]);

    }

    ////////////////////////////////////////////////////
    // part 2b: fold in the XY plane to make sure the 
    // point lives in the triangular cone just to the
    // right of the y axis
       
    M *= mirror(pos, vec3(1, 0, 0));
    
    //float p = pqr.x;
    float k = p >= 5.0 ? 4. : p >= 3.0 ? 2. : 1.;
    
    float theta = k * PI / p;

    m = vec3(-cos(theta), sin(theta), 0); // lq
    
    if (p >= 5.0) {        
        M *= mirror(pos, m);
        m = half_angle(m);
    }
    
    if (p >= 3.0) {
        M *= mirror(pos, m);
        m = half_angle(m);
    }
    
    M *= mirror(pos, m);    

    //////////////////////////////////////////////////////////////////////
    // part 3 - fill in the rest of the query
       
    // position relative to vertex
    vec3 rel_pos = pos - poly_vertex;
    
    // closest vertices and edge
    Q_vidx = -1;
    Q_eidx = -1;
    Q_vidx2 = -1;
             
    // for each potential face edge (perpendicular to each tri. edge)
    for (int eidx=0; eidx<3; ++eidx) {   
        
        vec3 tri_edge = tri_edges[eidx];
                        
        // polyhedron edge cut plane (passes thru origin and V, perpendicular
        // to triangle edge)
        vec3 poly_edge = poly_edges[eidx];
                                
        // signed distance from point to face edge
        float poly_edge_dist = dot(pos, poly_edge);

        // triangle vertex on the same side of face edge as point
        int vidx = (eidx + (poly_edge_dist > 0. ? 2 : 1)) % 3;
        
        // triangle vertex on opposite side of face edge as point
        int vidx2 = (eidx + (poly_edge_dist > 0. ? 1 : 2)) % 3;
        if (!is_face_normal[vidx2]) { vidx2 = vidx; }
                       
        // construct at the other polyhedron edge associated with the given
        // triangle vertex
        vec3 other_poly_edge = poly_edges[3-eidx-vidx];
        
        // construct the plane that bisects the two polyhedron edges
        vec3 bisector = cross(poly_vertex, poly_edge - other_poly_edge);
        
        float bisector_dist = dot(pos, bisector);
             
        if (bisector_dist >= 0.) {
            // if we are on the correct side of the associated
            // bisector, than we have found the closest triangle
            // edge & vertex.
            
            //Q.pdist_bisector = bisector_dist;
            pdist_poly_edge = poly_edge_dist;
            Q_eidx = eidx;
            Q_vidx = vidx;
            Q_vidx2 = vidx2;
            
        }
 
    }
    
}   

//////////////////////////////////////////////////////////////////////
// make a spherical polygon by repeated reflection across 2 edges
//
// inputs:
//
//   v: initial vertex position inside original triangle
//   a: first edge of orig. triangle to reflect across
//   b: second edge of orig. triangle to reflect across
//   M: transformation matrix that maps original verts to dst pos
//   

int make_polygon(vec3 v, vec3 a, vec3 b, mat3 M, out vec3 polygon[MAX_POLYGON]) {
    
    // polygon always includes the starting position
    polygon[0] = v;

    // index of last set polygon vertex
    int k = 0;
    
    // hold pair of edges and swap back and forth
    vec3 edges[2] = vec3[2]( a, b );
    
    // always start by mirroring across the edge v is not on
    int cur_edge = (abs(dot(v, edges[0])) < 0.01) ? 1 : 0;
            
    // we can get 0 or 1 vertex per iter, up to 10 vertices
    for (int i=0; i<MAX_POLYGON; ++i) {
        
        // reflect vertex across cur edge
        v = normalize(reflect(v, edges[cur_edge]));
        
        // reflect other edge across cur edge
        edges[1-cur_edge] = normalize(reflect(edges[1-cur_edge], edges[cur_edge]));
        
        if (dot(v, polygon[0]) > 0.99) {
            // if we have wrapped around back to the start, done!
            break;
        } else if (dot(v, polygon[k]) < 0.99) {
            // if the vertex was moved by the last reflection add it to the polygon
            k += 1;
            polygon[k] = v;
        }
        
        // swap edges
        cur_edge = 1 - cur_edge;
        
    }
    
    int npoly = k + 1;
    if (npoly < 3) { return npoly; }
    
    // determine winding order (CW or CCW) and flip if necessary 
    bool flip = dot(M*polygon[0], cross(M*polygon[1], M*polygon[2])) < 0.;
    
    // transform points from orig triangle to dst pos
    // and invert order if necessary; also figure out which is
    // canonical index 0 using a hash function
    vec3 Mpolygon[MAX_POLYGON];
    
    float dmin = 1e5;
    
    const vec3 dir = vec3(0.7027036 , 0.68125974, 0.56301879);
    
    int imin = 0;

    for (int i=0; i<MAX_POLYGON; ++i) {
        if (i >= npoly) { break; }
        Mpolygon[i] = M * polygon[flip ? npoly - i - 1 : i];
        float d = dot(dir, Mpolygon[i]);
        if (d < dmin) {
            imin = i;
            dmin = d;
        }
    }
    
    // shift elements to start at index 0
    for (int i=0; i<MAX_POLYGON; ++i) {
        if (i >= npoly) { break; }
        polygon[i] = Mpolygon[(i + imin) % npoly];
    }
    
    // number of points in the polygon
    return npoly;
    
}

//////////////////////////////////////////////////////////////////////
// distance between points on sphere

float sdist(vec3 a, vec3 b) {
    return acos(clamp(dot(a, b), -1.0, 1.0));
}

//////////////////////////////////////////////////////////////////////
// distance to arc on sphere
//
// inputs: 
//
//   p: query point (unit vector)
//   c: arc center point (unit vector)
//   r: arc radius in radians
//   l: lower tangent (unit vector)
//   w: upper tangent (unit vector)

float darc(vec3 p, vec3 p0, vec3 c, float r, vec3 l, vec3 w, vec3 p1) {
    
    if (dot(p, l) < 0.) {
        return sdist(p, p0);
    } else if (dot(p, w)*dot(p0, w) < 0.) {
        return sdist(p, p1);
    } else {
        return abs(sdist(p, c) - r);
    }

}

//////////////////////////////////////////////////////////////////////
//
// adapted from https://www.shadertoy.com/view/3dVfzc with some
// bugfixes and improvements
//
// compute a spline on the sphere made of two arcs that are tangent 
// to each other have desired tangents at given points
//
// inputs:
//
//    p: query point on sphere
//
//   p0: first point on sphere (unit vector)
//   l0: tangent vector at p0 (unit vector with dot(p0, l0) = 0)
//   p1: second point on sphere (unit vector) 
//   l1: tangent vector at p1 (unit vector with dot(p1, l1) = 0)
//
// output: distance to spline

float compute_spline(in vec3 p,
                     in vec3 p0, in vec3 l0,
                     in vec3 p1, in vec3 l1) {
                         
    // compute the line connecting p0 & p1
    vec3 tmp = normalize(cross(p0, p1));
    
    vec3 c0, c1, m, w;
    float r;

    // special case: p0, p1 coincident
    if (dot(p0, p1) > 0.999) {
        return sdist(p, p0);
    }
    
    vec3 q = normalize(cross(l0, l1));

    bool single_arc = false;

    // special case: p0 and p1 are connected by a segment of a great circle
    // the line from p0 to p1 hits them at the correct tangents 
    if (max(abs(dot(tmp, l0)), abs(dot(tmp, l1))) < 0.001) {
    
        c0 = normalize(cross(l0, l1));
        c1 = c0;
        
        r = 0.5*PI;
        
        m = normalize(l0 + l1);
        w = normalize(cross(m, c0));
        
        single_arc = true;
        
    } else if (dot(l0, l1) > 0.999) {
        
        // special case: single arc along common edge
        c0 = normalize(p0 + p1);
        c1 = c0;
        
        float c = dot(c0, p0);
        
        r = acos(c);
        
        m = c * c0 + sqrt(1.0 - c*c) * l0;
        w = normalize(cross(l0, c0));
                
        single_arc = true;
        
    } else if (abs(dot(q, p0) - dot(q, p1)) < 1e-3) {
    
        // special case: single arc around intersection of edges

        c0 = q;
        c1 = q;
        
        float c = dot(c0, p0);
        
        r = acos(c);
        
        vec3 l = normalize(l0 + l1);
        
        m = c*q + sqrt(1.0 - c*c)*l;
        w = normalize(cross(c0, m));
        
        single_arc = true;
        
    }
    
    if (single_arc) {
    
        vec3 P, L;

        if (dot(p, w) * dot(p0, w) > 0.) {
            P = p0;
            L = l0;
        } else {
            P = p1;
            L = l1;
        }

        if (dot(p, L) < 0.) {
            return sdist(p, P);
        } else {
            return abs(sdist(p, c0) - r);
        }
        
    }
    
    // compute the points orthogonal to (l0, p0) and (l1, p1), respectively
    vec3 a0 = cross(l0, p0);
    vec3 a1 = cross(l1, p1);
    
    // we will construct arc centers 
    //
    //   c0 = cos(r) * p0 + sin(r) * a0
    //   c1 = cos(r) * p1 + sin(r) * a1
    //
    // which are a distance r away from p0 & p1 respectively
    // by construction, dot(c0, l0) = dot(c1, l1) = 0
    //
    // now we want to solve for r such that dot(c0, c1) = cos(2*r)
    //
    // start by observing that 
    //
    //   (cos(r)²       * a +
    //    cos(r)*sin(r) * b
    //    sin(r)²       * c) = cos(2r)
    //
    // where a = dot(p0, p1), b = dot(p0, a1) + dot(p1, a0), and 
    // c = dot(a0, a1).
    //
    // applying the half angle identities and setting θ = 2r, we find
    //
    //   a*(1 + cos(θ))/2 + b*sin(θ)/2 + c*(1 - cos(θ))/2 = cos(θ)
    //   a*(1 + cos(θ)) + b*sin(θ)+ c*(1 - cos(θ)) = 2*cos(θ)
    //   (a - c - 2)*cos(θ) + b*sin(θ) = -(a + c)
    //
    // we can rewrite that as
    //
    //   d*cos(θ) + b*sin(θ) = e
    //
    // where d = a - c - 2 and e = -(a + c).
    //
    // finally, we can rewrite that as
    //
    //   α*cos(θ - φ) = e
    //
    // where α = sqrt(d² + b²) and φ = atan(b, d).
    // the solution is given by
    //
    //   θ = φ ± acos(e / α)
    //
    // and r = 0.5 * θ.
    
    float a = dot(p0, p1);
    float b = dot(p0, a1) + dot(p1, a0);
    float c = dot(a0, a1);
    
    float d = (a - c - 2.);
    float e = -(a + c);
    
    float alpha = length(vec2(d, b));
    float phi = atan(b, d); // in [-pi, pi]
    float tau = acos(e/alpha); // in [0, pi]

    // we want the r with the least magnitude so choose tau with the 
    // opposite sign as phi
    r = 0.5 * (phi > 0. ? phi - tau : phi + tau);

    // now get c0 & c1
    float cr = cos(r);
    float sr = sin(r);

    c0 = normalize(cr*p0 + sr*a0);
    c1 = normalize(cr*p1 + sr*a1);
    
    // m is the midpoint of c0 & c1, the point
    // of mutual tangency of the two arcs
    m = normalize(c0 + c1);
    
    // get the line connecting c0 & c1
    w = normalize(cross(c0, c1));
    
    // no longer need the sign of r, want it positive to compute distances later
    r = abs(r);
    
    float d0 = darc(p, p0, c0, r, l0, w, m);
    float d1 = darc(p, p1, c1, r, l1, w, m);
        
    return min(d0, d1);
                     
}

//////////////////////////////////////////////////////////////////////
// make a nice saturated color from a random color

vec3 saturate_color(vec3 c) {
    
    float lo = min(c.x, min(c.y, c.z));
    float hi = max(c.x, max(c.y, c.z));
    
    lo = min(lo, hi-0.05);
    
    return (c - lo) / (hi - lo);
    
}

//////////////////////////////////////////////////////////////////////
// draw the Truchet tiling given unique id for the sphere

vec3 draw_truchet(vec3 p, float id, float aa_scl) {

    // generate some random variables for this sphere
    vec3 r = hashwithoutsine31(19.*id + 101.);
        
    // choose tetraheral, octohedral, or icosahedral symmetry
    float pqr_p = 3.0 + floor(r.x * 3.0);

    // which of the 7 key points to place the vertex at?
    int spoint = int(floor(r.y * 7.0));

    // random bits used to influence shuffling & per-tile colors
    float extra = r.z * 1024.;

    // generate a random rotation for this sphere
    vec3 axis_angle = 2.*PI*hashwithoutsine31(id);
    
    float angle = length(axis_angle);
    vec3 axis = axis_angle / angle;
    
    // rotate the point
    p = rotate(axis, angle)*p;
    
    
    //////////////////////////////////////////////////
    // do wythoff construction for this sphere
        
    mat3 verts, edges, poly_edges, M;
    vec3 poly_vertex;
    int vidx, eidx, vidx2;
    float pdist_poly_edge;
    
    construct(vec3(pqr_p, 3, 2), spoint, p, 
              verts, edges, poly_vertex, poly_edges, 
              vidx, vidx2, eidx, M, pdist_poly_edge);
    
    
    // get face background color
    vec3 tri_vert = M * verts[vidx];
    
    vec3 face = M * verts[vidx];
    vec3 face2;
    
    if (vidx2 == vidx) {
        face2 = M * reflect(verts[vidx], poly_edges[eidx]);
    } else {
        face2 = M * verts[vidx2]; 
    }
        
    face = random_color_from_sphere(face);
    face2 = random_color_from_sphere(face2);
    
    face = mix(face2, face, smoothstep(-0.5*aa_scl, 0.5*aa_scl, abs(pdist_poly_edge)));
    
    vec3 color = 0.3*face + 0.65;
       
    //////////////////////////////////////////////////
    // construct the polygon by mirroring the 
    // polygon vertex around the triangle vertex
    // until we get back to where we started
       
    vec3 polygon[MAX_POLYGON];
    
    int a_eidx = (vidx + 1) % 3;
    int b_eidx = 3 - vidx - a_eidx;

    vec3 a = edges[a_eidx];
    vec3 b = edges[b_eidx];
    
    int npoly = make_polygon(poly_vertex, a, b, M, polygon);
    
    // get the lines / tangent vectors for each polygon
    // edge, and get two node points per polygon edge    
    vec3 pedges[MAX_POLYGON];
    vec3 nodes[2*MAX_POLYGON];
    
    // array of indices that will be shuffled to 
    // connect pairs of nodes
    int idx[2*MAX_POLYGON];

    // precompute some coefficients to do 
    // spherical linear interpolation (slerp)
    // along polygon edge
    float p0p1 = dot(polygon[0], polygon[1]);
    
    float phi = acos(p0p1);
    float sphi = sqrt(1.0 - p0p1*p0p1);
    float u = 0.3;
    
    // here's the slerp weights!
    float w0 = sin(u*phi)/sphi;
    float w1 = sin((1.-u)*phi)/sphi;

    // loop around the polygon generating nodes
    // and edges
    for (int i=0; i<MAX_POLYGON; ++i) {
        
        if (i >= npoly) { break; }
        
        vec3 p0 = polygon[i];
        vec3 p1 = polygon[(i+1) % npoly];
        
        pedges[i] = normalize(cross(p0, p1));
        
        nodes[2*i+0] = w0*p0 + w1*p1;
        nodes[2*i+1] = w1*p0 + w0*p1;
        
        idx[2*i+0] = 2*i+0;
        idx[2*i+1] = 2*i+1;  
        
    }
    
    // now generate a random seed for this polygon face
    const vec3 dir = vec3(0.876096, 0.80106629, 0.13512217);
    float seed = floor(63.*dot(tri_vert, dir)+0.5) + extra;

    // shuffle the order of nodes (we will connect up 
    // nodes with successive indices)
    shuffle(idx, 2*npoly, seed);    

    //////////////////////////////////////////////////
    // time to draw the splines between the nodes

    // for computing shadowing 
    float shadow = 1.0;
    bool was_painted = false;
    
    // half-width of splines that connect the nodes
    float width = 0.09*acos(p0p1);

    // shadow size
    float sz = 0.04 + 0.5*width;

    // for each pair of nodes
    for (int i=0; i<MAX_POLYGON; ++i) {
    
        if (i >= npoly) { break; }       
        
        // get points and tangent vectors
        vec3 p0 = nodes[idx[2*i+1]];
        vec3 l0 = pedges[idx[2*i+1]/2];

        vec3 p1 = nodes[idx[2*i+0]];
        vec3 l1 = pedges[idx[2*i+0]/2];
 
        // compute distance to spline
        float d = compute_spline(p, p0, l0, p1, l1);
        
        // deal with shadowing previously-drawn splines
        bool is_painted = d < width + 0.005;
        
        if (is_painted) {
            // current pixel in current spline, clear shadow
            shadow = 1.0;
            was_painted = true;
        } else if (was_painted) {
            // current pixel outside spline, shadow non-background pixels
            shadow = min(shadow, smoothstep(width - 0.25*sz, width + sz, d));
        }
        
        // pick a spline color
        vec3 src_color = saturate_color(hashwithoutsine31(seed));
        seed += 1.0;
    
        // draw outline and spline
        color *= smoothstep(0.0, aa_scl, d-width-0.01);        
        color = mix(src_color, color, smoothstep(0.0, aa_scl, d-width));

    }
    
    // deal with shadowing
    color *= shadow;
    
    //if (texture(iChannel0, vec2(69.5/256.0, 0.75)).x > 0.) {
    //    color *= smoothstep(0.0, aa_scl, abs(pdist_poly_edge)-0.005);
    //}
        
    // done!
    return color;
    
}

//////////////////////////////////////////////////////////////////////
// ray-sphere intersection

const vec4 miss = vec4(-1);

vec4 trace_sphere(in vec3 o, in vec3 d, in vec3 ctr, in float r, 
                  out float edge) {
    
    vec3 oc = o - ctr;
    
    float a = dot(d, d);
    float b = 2.0*dot(oc, d);
    float c = dot(oc, oc) - r*r;
        
    float D = b*b - 4.0*a*c;
    
    float tc = -dot(oc, d) / a;
    
    // distance from ray to sphere center, minus radius
    // should be zero for rays tangent to sphere
    edge = length(oc + tc*d) - r;
        
    if (D > 0.0) {
        
        float sqrtD = sqrt(D);
        
        float t = 0.5 * ( -b - sqrtD ) / a;
        
        if (t >= 0.0) {
            vec3 n = normalize( oc + t*d );
            return vec4(n, t);    
        }
        
    }
    
    return miss;
        
}

//////////////////////////////////////////////////////////////////////
// do the things

void main(void) {
    
    // distance from camera to sphere centers
    const float cdist = 10.0;
    
    // focal length in pixels
    float f = 0.25/resolution.y;
    
    // pixel size on center of sphere for antialiasing
    float aa_scl = (cdist - 1.0)*f;

    // rotation vector
    vec2 theta;
    
    // phase
    float t = time;
    
    // default rotation
    theta.y = 2.*PI*t/4.;
    theta.x = 2.*PI*t/16.0; // note we add a wiggle to this below
   
    // scroll speed 
    float shift = 0.25*t;
    
    // mouse sets rx & ry
    bool mouse_is_down = false;

    //if (max(mouse*resolution.xy.z, mouse*resolution.xy.w) > 0.05*resolution.y) { 
    //    theta.x = (mouse*resolution.xy.y - .5*resolution.y) * -5.0/resolution.y; 
    //    theta.y = (mouse*resolution.xy.x - .5*resolution.x) * 10.0/resolution.x; 
    //    mouse_is_down = true;;
    //}

    // integer and fractional part for drawing scrolling spheres
    float scroll = shift - floor(shift+0.5);
    float base_idx = -floor(shift+0.5);

    // light direction
    const vec3 L = normalize(vec3(-0.75, 1, -0.75));

    // ray origin and direction
    vec3 rd = normalize(vec3(f*(gl_FragCoord.xy - 0.5*resolution.xy), 1));
    vec3 ro = vec3(0, 0, -cdist);
    
    // for drawing circle edges
    float edge_min = 1e5;
    vec3 color = vec3(1);
    
    // sphere spacing
    const float spacing = 2.5;
    
    // max # of spheres
    const float max_spheres = 3.0;
    
    // draw spheres (note we will intersect at most one of them)
    for (float i=0.0; i<max_spheres; ++i) {
    
        // x coordinate of sphere center
        float cx = (i - 0.5*max_spheres+0.5 + scroll)*spacing;

        // raytrace to sphere
        float edge;
        vec4 intersect = trace_sphere(ro, rd, vec3(cx, 0, 0), 1.0, edge);
        edge_min = min(edge, edge_min);

        if (intersect.w >= 0.0) { // did we hit?
                        
            // figure out unique sphere id
            float hit_idx = i + base_idx;
        
            // figure out whether to wiggle x rotation
            float rx;
        
            if (mouse_is_down) {
                rx = theta.x;
            } else {
                rx = 0.35*PI*sin(theta.x + 2.0*PI*hit_idx/8.);
            }
            
            // intersection normal
            vec3 p = intersect.xyz;

            // rotate on sphere
            vec3 Rp = rotate(vec3(0, 1, 0), theta.y)*rotate(vec3(1, 0, 0), rx)*p;

            // draw our truchet tiling
            color = draw_truchet(Rp, hit_idx, aa_scl);

            // fake wrapped cosine lighting
            color *= 0.2*dot(p, L) + 0.8;

            // gentle specular highlight
            vec3 h = normalize(L - rd);
            float specAngle = max(dot(h, p), 0.0);
            float specular = pow(specAngle, 30.0);

            color = mix(color, vec3(1.0), 0.5*specular);

            // no more spheres to hit, done!
            break;
            
        } 
        
    }

    // draw sphere outline
    color *= smoothstep(0.0, aa_scl, abs(edge_min)-0.005);

    // "gamma correct" :P
    color = pow(color, vec3(0.7));

    glFragColor = vec4(color, 1);
    
}
