#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/stjGRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//build an sdf for visualization purposes.
float sdf_point(in vec2 point, in vec2 pos)
{
    vec2 delta = point - pos;
    return length(delta);
}

float sdf_line(in vec2 normal, in float offset, in vec2 pos)
{
    float proj_dist = dot(normal, pos);
    proj_dist -= offset;
    
    return abs(proj_dist);
}

float sdf_segment(in vec2 p1, in vec2 p2, in vec2 pos)
{
    //move pos into the coordinate system of the line, where the line is the x axis from 0 to 1.
    //If it's x coordinate is outside the line range, use the shortest point sdf.
    //else, use the line sdf.

    //gather data for the line sdf
    vec2 dp = p2 - p1;
    //vec2 normal = normalize(cross(vec3(dp, 0), vec3(0,0,1)).xy);
    vec2 normal = normalize(vec2(dp.y, -dp.x)); // complex rotation is valid in 2d
    float offset = dot(p1, normal);
    
    //find the tangent coordinate
    vec2 tangent = normalize(dp);
    float t_1 = dot(tangent, p1);
    float t_2 = dot(tangent, p2);
    float dt = t_2 - t_1;
    
    //manually project the x axis instead of a matrix, sdf_line handles the y.
    //maybe this is slower, but for this demo it shouldn't matter.
    float t_pos = dot(tangent, pos);
    
    //inverse lerp
    t_pos = (t_pos - t_1) / dt;
    
    //test within line
    if(t_pos < 0.0)
        return sdf_point(p1, pos);
    
    if(1.0 < t_pos)
        return sdf_point(p2, pos);
    
    return sdf_line(normal, offset, pos);
}

//find the winding number usint a pair of vertices and a point.
float wind_segment(in vec2 p1, in vec2 p2, in vec2 pos)
{
    //the winding number is the signed path length of the projeciton of a curve onto a unit circle of radius r.
    //this number is divided by its circumference, and means how many times the circle has gone around the point.
    
    vec2 d_p1 = normalize(p1 - pos);
    vec2 d_p2 = normalize(p2 - pos);
    
    //winding number starts at p1, ends at p2.
    //this can either be done via atan difference (probably has issues near the negative y direction)
    //float w1 = atan(d_p1.y, d_p1.x);
    //float w2 = atan(d_p2.y, d_p2.x);
    //return w2 - w1;
    
    //or, by acos of a normalized dot.
    float d = dot(d_p1, d_p2);
    float ac = acos(d);
    if(isnan(ac))
        return 0.0;
        
    //find winding sign
    float s = cross(vec3(d_p1, 0.0), vec3(d_p2, 0.0)).z;
    ac *= sign(s);
    
    return ac / (2.0 * 3.141592);
}

//this demo has one of the line segments move.
float moving_discontinuity(in vec2 uv, out float sdf)
{

    vec2[] verts = vec2[] (
        vec2( 0.5, 0.5),
        vec2(-0.5, 0.5),
        vec2(-0.5,-0.5),
        vec2( 0.5,-0.5)
    );
    
    //adjust the last line
    vec2 disp = vec2(0.2*sin(time / 2.0), 0.0);
    
    //display lines and generate winding number
    sdf = 100000.0;
    float wind = 0.0;
    for(int i=0; i<4; ++i)
    {
        vec2 v1 = verts[i];
        vec2 v2 = verts[(i+1)%4];
        
        if(i == 3)
        {
            v1 += disp;
            v2 += disp;
        }
        
        float t_sdf = sdf_segment(v1, v2, uv);
        if(t_sdf < sdf) sdf = t_sdf;
        
        wind += wind_segment(v1, v2, uv);
    }

    return wind;
}

//this demo has the line segment grow.
float growing_discontinuity(in vec2 uv, out float sdf)
{

    const int vert_count = 4;
    vec2[vert_count] verts = vec2[] (
        vec2( 0.5, 0.5),
        vec2(-0.5, 0.5),
        vec2(-0.5,-0.5),
        vec2( 0.5,-0.5)
    );
    
    //make a value grow for 3 seconds, and stop for two.
    float time = min(mod(time, 5.0), 3.0) / 3.0;
    
    //find the distance between each segment
    float[vert_count] dists;
    for(int i=0; i<vert_count; ++i)
        dists[i] = length(verts[(i+1)%vert_count] - verts[i]);
        
    //find the total distance for each segment
    //include a zero sum for comparisons later
    float[vert_count+1] sum_dists;
    sum_dists[0] = 0.0;
    for(int i=0; i<vert_count; ++i)
        sum_dists[i+1] = sum_dists[i] + dists[i];
    
    //normalize the dists by the total distance
    float[vert_count+1] pct_dists;
    for(int i=0; i<vert_count+1; ++i)
        pct_dists[i] = sum_dists[i] / sum_dists[vert_count];
    
    //convert time to the percentage path around a specific path segment
    //default is 100% of the polygon
    int segment = 4;
    float pct = 0.0;
    for(int i=0; i<vert_count; ++i)
    {
        if(pct_dists[i+1] <= time) continue;
        segment = i;
        
        //inverse lerp
        pct = (time - pct_dists[i]) / (pct_dists[i+1] - pct_dists[i]);
        break;
    }
    
    sdf = 100000.0;
    float wind = 0.0;
    
    //display points and winding number before the segment
    for(int i=0; i<segment; ++i)
    {
        vec2 v1 = verts[i];
        vec2 v2 = verts[(i+1)%vert_count];
    
        float t_sdf = sdf_segment(v1, v2, uv);
        if(t_sdf < sdf) sdf = t_sdf;
        
        wind += wind_segment(v1, v2, uv);
    }

    //display the next point to a calculated point (lerp)
    if(segment != vert_count)
    {
        vec2 v1 = verts[segment];
        vec2 v2 = mix(verts[segment], verts[(segment+1)%vert_count], pct);
        float t_sdf = sdf_segment(v1, v2, uv);
        if(t_sdf < sdf) sdf = t_sdf;

        wind += wind_segment(v1, v2, uv);
    }

    return wind;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = mix(vec2(-1,-1), vec2(1,1), uv);
    uv.x *= resolution.x/resolution.y;

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    //sdf testing
    //col *= 1.0 - exp(-50.0*sdf_line(normal, offset, uv));
    //col *= 1.0 - exp(-50.0*sdf_point(verts[0], uv));
    
    float sdf = 100000.0;
    //float wind = moving_discontinuity(uv, sdf);
    float wind = growing_discontinuity(uv, sdf);
    
    //alternative visualizations
    col = vec3(1.0);
    //col = 0.5 + 0.5*cos((2.0*3.141592) *5.0*wind + time+uv.xyx+vec3(0,2,4));
    
    col *= 0.5 * wind + 0.5;
    
    //col *= 1.0 - exp(-100.0*sdf);
    if(sdf < 0.005) col *= 0.0;

    // Output to screen
    glFragColor = vec4(col,1.0);
    
    //glFragColor = vec4(uv, 0.0, 1.0);
    
}
