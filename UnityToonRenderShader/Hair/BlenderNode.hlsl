// Translate Matrix
float4x4 OffsetMatrix(float3 xyzOffset)
{
	return float4x4(
		1,0,0,xyzOffset.x,
		0,1,0,xyzOffset.y,
		0,0,1,xyzOffset.z,
		0,0,0,1
	);
}
// Rotate Matrix
float4x4 RotateMatrix_X(float3 xyzRotate)
{
    return float4x4(
		1,0,0,0,
		0,cos(xyzRotate.x),-sin(xyzRotate.x),0,
		0,sin(xyzRotate.x),cos(xyzRotate.x),0,
		0,0,0,1
	);
}
float4x4 RotateMatrix_Y(float3 xyzRotate)
{
    return float4x4(
		cos(xyzRotate.x),0,sin(xyzRotate.x),0,
		0,1,0,0,
		-sin(xyzRotate.x),0,cos(xyzRotate.x),0,
		0,0,0,1
	);
}
float4x4 RotateMatrix_Z(float3 xyzRotate)
{
    return float4x4(
		cos(xyzRotate.x),-sin(xyzRotate.x),0,0,
		sin(xyzRotate.x),cos(xyzRotate.x),0,0,
		0,0,1,0,
		0,0,0,1
	);
}
// Scale Matrix
float4x4 ScaleMatrix(float3 xyzScale)
{
	return float4x4(
		xyzScale.x,0,0,0,
		0,xyzScale.y,0,0,
		0,0,xyzScale.z,0,
		0,0,0,1
	);
}

// Vector Transform Node(Object->View)
float3 VertesTranformFromObjectToView(float3 NormalOS)
{
    return normalize(TransformWorldToViewDir(normalize(GetVertexNormalInputs(NormalOS).normalWS)));
}
// Mapping Node(Texture)
float3 MappingNode_Tex(float3 normalInput,float3 xyzOffset,float3 xyzRotate,float3 xyzScale)
{
    float4 nor = float4(normalInput,1);
    nor = mul(OffsetMatrix(xyzOffset),nor);
    nor = mul(RotateMatrix_X(xyzRotate),nor);
    nor = mul(RotateMatrix_Y(xyzRotate),nor);
    nor = mul(RotateMatrix_Z(xyzRotate),nor);
    nor = mul(ScaleMatrix(xyzScale),nor);
    normalInput = frac(nor.xyz);
    return normalInput;
}
// Color Gradient Node
float4 ColorGradient(float4 colorStart,float4 colorEnd,float pos)
{
    float4 col = float4(0,0,0,0);
	col = lerp(colorStart,colorEnd,pos);
	return col;
}
// Reverse Node
float Reverse(float value)
{
    return 1 - value;
}
float Reverse(float2 value)
{
    return 1 - value;
}
float Reverse(float3 value)
{
    return 1 - value;
}
float Reverse(float4 value)
{
    return 1 - value;
}

