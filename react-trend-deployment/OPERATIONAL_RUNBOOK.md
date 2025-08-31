# React Trend Application - Operational Runbook

## Quick Reference Guide

### 🚨 Emergency Contacts
- **On-Call Engineer**: [Your Contact]
- **AWS Support**: [Support Case Portal]
- **Team Lead**: [Lead Contact]

### 🔗 Critical URLs
- **Application**: http://a33f4d4d9655c4121a50242bb0a3942b-321113.us-west-2.elb.amazonaws.com
- **Grafana Monitoring**: http://aa29945fe1c614be5ae0b521f91e2e87-1553642504.us-west-2.elb.amazonaws.com:3000
- **Jenkins CI/CD**: http://54.68.35.10:8080
- **GitHub Repository**: https://github.com/Surya-pkh/Projects/tree/main/react-trend-deployment

---

## 🚨 Emergency Procedures

### Application Not Responding
```bash
# 1. Check application health
curl -I http://a33f4d4d9655c4121a50242bb0a3942b-321113.us-west-2.elb.amazonaws.com

# 2. Check pods status
kubectl get pods -n trend

# 3. Check recent logs
kubectl logs -n trend deployment/trend-app --tail=50

# 4. If needed, restart pods
kubectl rollout restart deployment/trend-app -n trend
```

### High CPU/Memory Usage
```bash
# Check resource usage
kubectl top pods -n trend

# Scale up if needed
kubectl scale deployment trend-app --replicas=5 -n trend

# Check HPA status
kubectl get hpa -n trend
```

### Jenkins Pipeline Failing
1. Check Jenkins console logs
2. Verify AWS/Docker credentials
3. Check EKS cluster connectivity
4. Manually deploy if critical: `kubectl apply -f kubernetes/`

---

## 📊 Monitoring & Alerting

### Key Metrics to Watch
- **Application Uptime**: Should be > 99.5%
- **Response Time**: Should be < 2 seconds
- **Error Rate**: Should be < 1%
- **Pod CPU Usage**: Should be < 80%
- **Pod Memory Usage**: Should be < 80%

### Grafana Dashboard URLs
- **Main Dashboard**: Use grafana-dashboard-v1.json
- **Detailed Metrics**: Use grafana-dashboard-v2.json

### Common Alert Scenarios
1. **Pod Down**: Check `kubectl get pods -n trend`
2. **High Error Rate**: Check nginx logs and application logs
3. **Resource Exhaustion**: Scale up deployment
4. **Load Balancer Issues**: Check AWS Load Balancer console

---

## 🔄 Deployment Procedures

### Standard Deployment (via Jenkins)
1. Push code changes to `main` branch
2. Jenkins automatically triggers build
3. Monitor build progress at Jenkins URL
4. Verify deployment in Grafana

### Emergency Deployment
```bash
# 1. Build new image
docker build -t suryapkh/trend-app:emergency-$(date +%Y%m%d) .
docker push suryapkh/trend-app:emergency-$(date +%Y%m%d)

# 2. Update deployment
kubectl set image deployment/trend-app trend-app=suryapkh/trend-app:emergency-$(date +%Y%m%d) -n trend

# 3. Monitor rollout
kubectl rollout status deployment/trend-app -n trend
```

### Rollback Procedure
```bash
# Check deployment history
kubectl rollout history deployment/trend-app -n trend

# Rollback to previous version
kubectl rollout undo deployment/trend-app -n trend

# Or rollback to specific revision
kubectl rollout undo deployment/trend-app --to-revision=2 -n trend
```

---

## 🛠 Maintenance Tasks

### Daily Health Checks
- [ ] Check Grafana dashboards for anomalies
- [ ] Verify all pods are running: `kubectl get pods -n trend`
- [ ] Check application accessibility
- [ ] Review error logs

### Weekly Maintenance
- [ ] Update Docker images with security patches
- [ ] Review resource utilization trends
- [ ] Clean up old Docker images
- [ ] Backup terraform state files

### Monthly Tasks
- [ ] Review and update documentation
- [ ] Security audit
- [ ] Performance optimization review
- [ ] Update Kubernetes cluster if needed

---

## 🔍 Troubleshooting Guide

### Issue: Pods Stuck in Pending State
**Diagnosis:**
```bash
kubectl describe pod <pod-name> -n trend
kubectl get nodes
```
**Solution:**
- Check node resources
- Verify node labels and taints
- Scale cluster if needed

### Issue: Application Returns 503 Errors
**Diagnosis:**
```bash
kubectl get svc -n trend
kubectl get endpoints -n trend
curl -I http://<service-ip>
```
**Solution:**
- Check service selector matches pod labels
- Verify pod readiness probes
- Check nginx configuration

### Issue: Monitoring Data Missing
**Diagnosis:**
```bash
kubectl logs -n monitoring deployment/prometheus
kubectl get targets # via Prometheus UI
```
**Solution:**
- Verify Prometheus RBAC permissions
- Check service discovery configuration
- Ensure metrics endpoints are accessible

### Issue: CI/CD Pipeline Failures
**Common Causes:**
1. **Docker Hub authentication**: Update credentials in Jenkins
2. **AWS permissions**: Verify IAM roles and policies
3. **EKS connectivity**: Check security groups and network ACLs
4. **Resource limits**: Check if cluster has sufficient resources

---

## 📋 Operational Checklists

### Pre-Deployment Checklist
- [ ] Code reviewed and approved
- [ ] Tests passing locally
- [ ] Backup current deployment
- [ ] Notify stakeholders of deployment window
- [ ] Monitor systems during deployment

### Post-Deployment Checklist
- [ ] Verify application accessibility
- [ ] Check all pods are running and ready
- [ ] Verify metrics are flowing to Prometheus
- [ ] Check error rates in logs
- [ ] Update documentation if needed

### Incident Response Checklist
- [ ] Assess severity and impact
- [ ] Notify team and stakeholders
- [ ] Document timeline and actions taken
- [ ] Implement immediate fixes
- [ ] Plan and execute permanent solution
- [ ] Conduct post-incident review

---

## 📞 Escalation Matrix

### Severity Levels
- **P1 (Critical)**: Application completely down
- **P2 (High)**: Major functionality impaired
- **P3 (Medium)**: Minor functionality issues
- **P4 (Low)**: Cosmetic or documentation issues

### Response Times
- **P1**: 15 minutes
- **P2**: 1 hour
- **P3**: 4 hours
- **P4**: Next business day

### Escalation Path
1. **First Response**: On-call engineer
2. **Second Level**: Team lead
3. **Third Level**: Manager + AWS support
4. **Final Level**: Director level

---

## 🔒 Security Procedures

### Access Management
- EKS cluster access via AWS IAM
- Jenkins access via username/password
- Grafana access via admin credentials
- Rotate credentials quarterly

### Security Monitoring
- Monitor for unauthorized access attempts
- Review IAM policies regularly
- Keep all components updated
- Scan container images for vulnerabilities

### Incident Response
1. Isolate affected systems
2. Assess extent of compromise
3. Preserve logs and evidence
4. Notify security team
5. Implement containment measures

---

## 📊 Performance Baselines

### Normal Operating Parameters
- **CPU Usage**: 20-40% average
- **Memory Usage**: 30-50% average
- **Response Time**: 500ms-1.5s average
- **Throughput**: 100-500 requests/minute
- **Error Rate**: < 0.5%

### Performance Thresholds
- **Warning**: CPU > 70%, Memory > 70%
- **Critical**: CPU > 90%, Memory > 90%
- **Alert**: Response time > 3s, Error rate > 2%

---

## 📝 Change Management

### Standard Changes
- Minor configuration updates
- Security patches
- Documentation updates

### Emergency Changes
- Critical security fixes
- System outage resolution
- Data corruption fixes

### Change Approval Process
1. Create change request
2. Technical review
3. Manager approval (for major changes)
4. Schedule implementation
5. Post-change verification

---

## 📚 Knowledge Base

### Useful Commands
```bash
# Application scaling
kubectl scale deployment trend-app --replicas=N -n trend

# Resource monitoring
kubectl top nodes
kubectl top pods -n trend

# Log analysis
kubectl logs -n trend deployment/trend-app --previous
kubectl logs -n trend deployment/trend-app -f

# Configuration updates
kubectl rollout restart deployment/trend-app -n trend
kubectl get configmap -n trend
```

### Configuration Files
- **Kubernetes Manifests**: `/kubernetes/` directory
- **Monitoring Config**: `/monitoring/` directory
- **Infrastructure**: `/terraform/` directory
- **Application Config**: `nginx.conf`, `Dockerfile`

### External Dependencies
- **Docker Hub**: Container registry
- **GitHub**: Source code repository
- **AWS EKS**: Kubernetes cluster
- **AWS EC2**: Jenkins instance
- **AWS VPC**: Network infrastructure

---

*Runbook Version: 1.0*  
*Last Updated: August 31, 2025*  
*Review Frequency: Monthly*
