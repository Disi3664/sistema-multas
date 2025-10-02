function verificarApiKey(req, res, next) {
    const apiKey = req.headers['x-api-key'];
    
    if (!apiKey) {
        return res.status(401).json({ 
            error: 'API Key requerida',
            message: 'Debe proporcionar una API Key en el header X-API-Key'
        });
    }
    
    if (apiKey !== process.env.API_KEY) {
        return res.status(403).json({ 
            error: 'API Key inválida',
            message: 'La API Key proporcionada no es válida'
        });
    }
    
    next();
}

module.exports = { verificarApiKey };
